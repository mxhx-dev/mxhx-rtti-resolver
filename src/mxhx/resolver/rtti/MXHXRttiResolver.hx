/*
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
 */

package mxhx.resolver.rtti;

import haxe.Resource;
import haxe.rtti.CType;
import haxe.rtti.XmlParser;
import mxhx.manifest.MXHXManifestEntry;
import mxhx.resolver.IMXHXResolver;
import mxhx.resolver.MXHXResolvers;
import mxhx.symbols.IMXHXAbstractSymbol;
import mxhx.symbols.IMXHXAbstractToOrFromInfo;
import mxhx.symbols.IMXHXArgumentSymbol;
import mxhx.symbols.IMXHXClassSymbol;
import mxhx.symbols.IMXHXEnumFieldSymbol;
import mxhx.symbols.IMXHXEnumSymbol;
import mxhx.symbols.IMXHXEventSymbol;
import mxhx.symbols.IMXHXFieldSymbol;
import mxhx.symbols.IMXHXFunctionTypeSymbol;
import mxhx.symbols.IMXHXInterfaceSymbol;
import mxhx.symbols.IMXHXSymbol;
import mxhx.symbols.IMXHXTypeSymbol;
import mxhx.symbols.MXHXSymbolTools;
import mxhx.symbols.internal.MXHXAbstractSymbol;
import mxhx.symbols.internal.MXHXAbstractToOrFromInfo;
import mxhx.symbols.internal.MXHXArgumentSymbol;
import mxhx.symbols.internal.MXHXClassSymbol;
import mxhx.symbols.internal.MXHXEnumFieldSymbol;
import mxhx.symbols.internal.MXHXEnumSymbol;
import mxhx.symbols.internal.MXHXFieldSymbol;
import mxhx.symbols.internal.MXHXFunctionTypeSymbol;
import mxhx.symbols.internal.MXHXInterfaceSymbol;

/**
	An MXHX resolver that uses the [Haxe Runtime Type Information](https://haxe.org/manual/cr-rtti.html)
	to resolve symbols.
**/
class MXHXRttiResolver implements IMXHXResolver {
	private static final META_ENUM = ":enum";
	private static final META_DEFAULT_XML_PROPERTY = "defaultXmlProperty";

	public function new() {
		manifests = MXHXResolvers.emitMappings();
	}

	private var manifests:Map<String, Map<String, MXHXManifestEntry>> /* Map<Uri<TagName, Qname>> */ = [];
	private var qnameToMXHXTypeSymbolLookup:Map<String, IMXHXTypeSymbol> = [];

	public function registerManifest(uri:String, mappings:Map<String, MXHXManifestEntry>):Void {
		manifests.set(uri, mappings);
	}

	public function resolveTag(tagData:IMXHXTagData):IMXHXSymbol {
		if (tagData == null) {
			return null;
		}
		if (!hasValidPrefix(tagData)) {
			return null;
		}
		var resolvedProperty = resolveTagAsPropertySymbol(tagData);
		if (resolvedProperty != null) {
			return resolvedProperty;
		}
		var resolvedEvent = resolveTagAsEventSymbol(tagData);
		if (resolvedEvent != null) {
			return resolvedEvent;
		}
		return resolveTagAsTypeSymbol(tagData);
	}

	public function resolveAttribute(attributeData:IMXHXTagAttributeData):IMXHXSymbol {
		if (attributeData == null) {
			return null;
		}
		var tagData:IMXHXTagData = attributeData.parentTag;
		var tagSymbol = resolveTag(tagData);
		if (tagSymbol == null || !(tagSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast tagSymbol;
		var field = MXHXSymbolTools.resolveFieldByName(classSymbol, attributeData.shortName);
		if (field != null) {
			return field;
		}
		var event = MXHXSymbolTools.resolveEventByName(classSymbol, attributeData.shortName);
		if (event != null) {
			return event;
		}
		return null;
	}

	public function resolveTagField(tagData:IMXHXTagData, fieldName:String):IMXHXFieldSymbol {
		var tagSymbol = resolveTag(tagData);
		if (tagSymbol == null || !(tagSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast tagSymbol;
		return MXHXSymbolTools.resolveFieldByName(classSymbol, fieldName);
	}

	public function resolveQname(qname:String):IMXHXTypeSymbol {
		if (qname == null) {
			return null;
		}
		var resolved = qnameToMXHXTypeSymbolLookup.get(qname);
		if (resolved != null) {
			return resolved;
		}
		if (StringTools.startsWith(qname, "StdTypes.")) {
			qname = qname.substr(9);
		}
		var nameToResolve = qname;
		var paramsStart = qname.indexOf("<");
		var params:Array<IMXHXTypeSymbol> = [];
		if (paramsStart != -1) {
			nameToResolve = qname.substr(0, paramsStart);
			params = qnameToParams(qname, paramsStart);
			// unlike the macro resolver, we can't easily detect when a qname
			// represents a type parameter because type parameters are
			// CType.CClass, like regular classes.
			// but qnameToParams() will return null for type parameters, so
			// we can check the cache again.
			qname = '$nameToResolve<${params.map(param -> param != null ? param.qname : "%").join(",")}>';
			var resolved = qnameToMXHXTypeSymbolLookup.get(qname);
			if (resolved != null) {
				return resolved;
			}
		}
		if (nameToResolve == "haxe.Constraints.Function") {
			nameToResolve = "haxe.Function";
			var resolved = qnameToMXHXTypeSymbolLookup.get(nameToResolve);
			if (resolved != null) {
				return resolved;
			}
		}
		// these built-in abstracts don't resolve consistently across targets at runtime
		switch (nameToResolve) {
			case "Any" | "Bool" | "Class" | "Dynamic" | "Enum" | "EnumValue" | "Float" | "Int" | "Null" | "UInt" | "haxe.Function":
				return createMXHXAbstractSymbolForBuiltin(nameToResolve, params);
			default:
		}
		if (nameToResolve.charAt(0) == "(") {
			return createMXHXFunctionTypeSymbolFromQname(nameToResolve);
		}
		var classTypeTree:TypeTree = null;
		var resolvedEnum = Type.resolveEnum(nameToResolve);
		if ((resolvedEnum is Enum)) {
			var enumTypeTree:TypeTree;
			try {
				enumTypeTree = getTypeTree(resolvedEnum);
			} catch (e:Dynamic) {
				return createMXHXEnumSymbolForEnum(resolvedEnum, params);
			}
			switch (enumTypeTree) {
				case TEnumdecl(enumdef):
					return createMXHXEnumSymbolForEnumdef(enumdef, params);
				default:
					return createMXHXEnumSymbolForEnum(resolvedEnum, params);
			}
		}
		var resolvedClass = Type.resolveClass(nameToResolve);
		if (resolvedClass == null) {
			// an abstract might not exist at runtime,
			// but its rtti data may have been embedded
			classTypeTree = getMxhxFallbackTypeTree(nameToResolve);
			if (classTypeTree == null) {
				return null;
			}
		}

		if (classTypeTree == null) {
			try {
				classTypeTree = getTypeTree(resolvedClass);
			} catch (e:Dynamic) {
				return createMXHXClassSymbolForClass(resolvedClass, params);
			}
			if (classTypeTree == null) {
				return createMXHXClassSymbolForClass(resolvedClass, params);
			}
		}
		switch (classTypeTree) {
			case TClassdecl(classdef):
				if (classdef.module != null && classdef.module != classdef.path) {
					var lastDotIndex = classdef.path.lastIndexOf(".");
					var moduleQname = classdef.module + "." + classdef.path.substr(lastDotIndex + 1);
					if (classdef.params.length > 0) {
						moduleQname += "<" + classdef.params.map(param -> "%").join(",") + ">";
					}
					var resolved = qnameToMXHXTypeSymbolLookup.get(moduleQname);
					if (resolved != null) {
						return resolved;
					}
				}
				if (classdef.isInterface) {
					return createMXHXInterfaceSymbolForClassdef(classdef, params);
				}
				return createMXHXClassSymbolForClassdef(classdef, params, false);
			case TEnumdecl(enumdef):
				if (enumdef.module != null && enumdef.module != enumdef.path) {
					var lastDotIndex = enumdef.path.lastIndexOf(".");
					var moduleQname = enumdef.module + "." + enumdef.path.substr(lastDotIndex + 1);
					if (enumdef.params.length > 0) {
						moduleQname += "<" + enumdef.params.map(param -> "%").join(",") + ">";
					}
					var resolved = qnameToMXHXTypeSymbolLookup.get(moduleQname);
					if (resolved != null) {
						return resolved;
					}
				}
				return createMXHXEnumSymbolForEnumdef(enumdef, params);
			case TAbstractdecl(abstractdef):
				if (abstractdef.module != abstractdef.path) {
					var lastDotIndex = abstractdef.path.lastIndexOf(".");
					var moduleQname = abstractdef.module + "." + abstractdef.path.substr(lastDotIndex + 1);
					var resolved = qnameToMXHXTypeSymbolLookup.get(moduleQname);
					if (resolved != null) {
						return resolved;
					}
				}
				if (Lambda.exists(abstractdef.meta, m -> m.name == ":enum")) {
					return createMXHXEnumSymbolForAbstractdef(abstractdef, params);
				}
				return createMXHXAbstractSymbolForAbstractdef(abstractdef, params);
			case TTypedecl(t):
				var newQname = cTypeToQname(t.type);
				if (newQname != null) {
					return resolveQname(newQname);
				}
				return null;
			default:
				return null;
		}
	}

	private static function getMxhxFallbackTypeTree(qname:String):TypeTree {
		var rtti = Resource.getString('__mxhxRtti_${qname}');
		if (rtti == null) {
			return null;
		}
		var x = Xml.parse(rtti).firstElement();
		if (x == null) {
			return null;
		}
		return new haxe.rtti.XmlParser().processElement(x);
	}

	private static function getTypeTree(c:Any):TypeTree {
		var __rtti = Reflect.field(c, "__rtti");
		var rtti:String = null;
		if (__rtti != null) {
			// Std.downcast() with String doesn't seem to work on all targets
			rtti = Std.string(__rtti);
		}
		if (rtti == null) {
			var typeName = if ((c is Enum)) {
				var e:Enum<Dynamic> = cast c;
				e.getName();
			} else {
				Type.getClassName(c);
			}
			var fallback = getMxhxFallbackTypeTree(typeName);
			if (fallback != null) {
				return fallback;
			}
			if ((c is Class)) {
				throw 'Class ${Type.getClassName(c)} has no RTTI information, consider adding @:rtti';
			} else if ((c is Enum)) {
				throw 'Enum ${Type.getEnumName(c)} has no RTTI information, consider adding @:rtti';
			} else {
				throw 'Value ${c} has no RTTI information, consider adding @:rtti';
			}
		}
		var x = Xml.parse(rtti).firstElement();
		if (x == null) {
			return null;
		}
		return new haxe.rtti.XmlParser().processElement(x);
	}

	private function createMXHXFunctionTypeSymbolFromQname(qname:String):IMXHXFunctionTypeSymbol {
		var splitResult = splitFunctionTypeQname(qname);
		var argStrings = splitResult.args;
		var retString = splitResult.ret;
		var args = argStrings.map(function(argString):IMXHXArgumentSymbol {
			var opt = argString.charAt(0) == "?";
			if (opt) {
				argString = argString.substr(1);
			}
			var argName:String = null;
			var colonIndex = argString.indexOf(":");
			if (colonIndex != -1) {
				argName = argString.substring(0, colonIndex);
				argString = argString.substring(colonIndex + 1);
			}
			var type = resolveQname(argString);
			return new MXHXArgumentSymbol(argName, type, opt);
		});
		var ret = resolveQname(retString);

		var functionType = new MXHXFunctionTypeSymbol(qname, args, ret);
		functionType.qname = qname;
		qnameToMXHXTypeSymbolLookup.set(qname, functionType);
		return functionType;
	}

	public function getTagNamesForQname(qnameToFind:String):Map<String, String> {
		var result:Map<String, String> = [];
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				if (manifestEntry.qname == qnameToFind) {
					result.set(uri, tagName);
				}
			}
		}
		return result;
	}

	public function getParamsForQname(qnameToFind:String):Array<String> {
		var index = qnameToFind.indexOf("<");
		if (index != -1) {
			qnameToFind = qnameToFind.substr(0, index);
		}
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				if (manifestEntry.qname == qnameToFind) {
					var params = manifestEntry.params;
					if (params == null) {
						return [];
					}
					return params.copy();
				}
			}
		}
		return [];
	}

	public function getTypes():Array<IMXHXTypeSymbol> {
		var result:Map<String, IMXHXTypeSymbol> = [];
		// the following code resolves only known mappings,
		// but any class is technically able to be completed,
		// so this implementation is incomplete
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				var qname = manifestEntry.qname;
				if (!result.exists(qname)) {
					var symbol = resolveQname(qname);
					if (symbol != null) {
						result.set(qname, symbol);
					}
				}
			}
		}
		return Lambda.array(result);
	}

	private function classToQname(resolvedClass:Class<Dynamic>, params:Array<IMXHXTypeSymbol> = null):String {
		var qname = Type.getClassName(resolvedClass);
		if (qname == null) {
			return null;
		}
		var dotIndex = qname.lastIndexOf(".");
		var name = qname;
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			name = qname.substr(dotIndex + 1);
			var packString = qname.substr(0, dotIndex);
			pack = packString.split(".");
		}
		var moduleName = name;
		if (pack.length > 0) {
			moduleName = pack.join(".") + "." + name;
		}
		return MXHXResolverTools.definitionToQname(name, pack, moduleName, params != null ? params.map(param -> param != null ? param.qname : null) : []);
	}

	private function createMXHXAbstractSymbolForBuiltin(qname:String, params:Array<IMXHXTypeSymbol>):IMXHXAbstractSymbol {
		var dotIndex = qname.lastIndexOf(".");
		var name = qname;
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			name = qname.substr(dotIndex + 1);
			var packString = qname.substr(0, dotIndex);
			pack = packString.split(".");
		}
		var moduleName = name;
		if (pack.length > 0) {
			moduleName = pack.join(".") + "." + name;
		}
		qname = MXHXResolverTools.definitionToQname(name, pack, moduleName, params.map(param -> param != null ? param.qname : null));
		var result = new MXHXAbstractSymbol(name, pack, params);
		result.qname = qname;
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		return result;
	}

	private function createMXHXClassSymbolForClass(resolvedClass:Class<Dynamic>, params:Array<IMXHXTypeSymbol>):IMXHXClassSymbol {
		var qname = Type.getClassName(resolvedClass);
		if (qname == null) {
			return null;
		}
		var dotIndex = qname.lastIndexOf(".");
		var name = qname;
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			name = qname.substr(dotIndex + 1);
			var packString = qname.substr(0, dotIndex);
			pack = packString.split(".");
		}
		var moduleName = name;
		if (pack.length > 0) {
			moduleName = pack.join(".") + "." + name;
		}
		qname = MXHXResolverTools.definitionToQname(name, pack, moduleName, params.map(param -> param != null ? param.qname : null));
		var result = new MXHXClassSymbol(name, pack, params);
		result.qname = qname;
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		var resolvedSuperClass = Type.getSuperClass(resolvedClass);
		if (resolvedSuperClass != null) {
			var superClassQname = classToQname(resolvedSuperClass);
			var classType = resolveQname(superClassQname);
			if (!(classType is IMXHXClassSymbol)) {
				throw 'Expected class: ${classType.qname}. Is it missing @:rtti metadata?';
			}
			result.superClass = cast(classType, IMXHXClassSymbol);
		}
		result.paramNames = pack.length == 0 && name == "Array" ? ["T"] : [];
		var fields:Array<IMXHXFieldSymbol> = [];
		// fields = fields.concat(Type.getInstanceFields(resolvedClass).map(field -> createMXHXFieldSymbolForTypeField(field, false)));
		// fields = fields.concat(Type.getClassFields(resolvedClass).map(field -> createMXHXFieldSymbolForTypeField(field, true)));
		result.fields = fields;

		return result;
	}

	private function createMXHXClassSymbolForClassdef(classdef:Classdef, params:Array<IMXHXTypeSymbol>, abstractImpl:Bool):IMXHXClassSymbol {
		var name = classdef.path;
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = classdef.module;
		// if it's the implementation of an abstract, the module property will
		// point to the abstract, but the path will be more technically correct
		// because it rewrites the abstract name to start with a _ character
		if (moduleName == null || abstractImpl) {
			moduleName = classdef.path;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXClassSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		result.doc = classdef.doc;
		result.file = classdef.file;
		// result.offsets = {start: pos.min, end: pos.max};
		result.isPrivate = classdef.isPrivate;
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		if (classdef.superClass != null) {
			var classType = resolveQname(classdef.superClass.path);
			if (!(classType is IMXHXClassSymbol)) {
				throw 'Expected class: ${classType.qname}. Is it missing @:rtti metadata?';
			}
			result.superClass = cast(classType, IMXHXClassSymbol);
		}
		var resolvedInterfaces:Array<IMXHXInterfaceSymbol> = [];
		for (currentInterface in classdef.interfaces) {
			var interfaceType = resolveQname(currentInterface.path);
			if (!(interfaceType is IMXHXInterfaceSymbol)) {
				throw 'Expected interface: ${interfaceType.qname}. Is it missing @:rtti metadata? 1: ${classdef.path}';
			}
			var resolvedInterface = cast(interfaceType, IMXHXInterfaceSymbol);
			resolvedInterfaces.push(resolvedInterface);
		}
		result.interfaces = resolvedInterfaces;
		result.params = params != null ? params : [];
		result.paramNames = classdef.params.copy();
		var fields:Array<IMXHXFieldSymbol> = [];
		fields = fields.concat(classdef.fields.map(field -> createMXHXFieldSymbolForClassField(field, false, classdef, result)));
		fields = fields.concat(classdef.statics.map(field -> createMXHXFieldSymbolForClassField(field, true, classdef, result)));
		result.fields = fields;
		if (classdef.meta != null) {
			result.meta = classdef.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		// result.events = classdef.meta.map(eventMeta -> {
		// 	if (eventMeta.name != ":event") {
		// 		return null;
		// 	}
		// 	if (eventMeta.params.length != 1) {
		// 		return null;
		// 	}
		// 	var eventName = getEventName(eventMeta);
		// 	if (eventName == null) {
		// 		return null;
		// 	}
		// 	var eventTypeQname = getEventType(eventMeta);
		// 	var resolvedType:IMXHXClassSymbol = cast resolveQname(eventTypeQname);
		// 	var result:IMXHXEventSymbol = new MXHXEventSymbol(eventName, resolvedType);
		// 	return result;
		// }).filter(eventSymbol -> eventSymbol != null);
		result.defaultProperty = getDefaultProperty(classdef);
		return result;
	}

	private function createMXHXInterfaceSymbolForClassdef(classdef:Classdef, params:Array<IMXHXTypeSymbol>):IMXHXInterfaceSymbol {
		var name = classdef.path;
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = classdef.module;
		if (moduleName == null) {
			moduleName = classdef.path;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXInterfaceSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		result.doc = classdef.doc;
		result.file = classdef.file;
		// result.offsets = {start: pos.min, end: pos.max};
		result.isPrivate = classdef.isPrivate;
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		var resolvedInterfaces:Array<IMXHXInterfaceSymbol> = [];
		for (currentInterface in classdef.interfaces) {
			var interfaceType = resolveQname(currentInterface.path);
			if (!(interfaceType is IMXHXInterfaceSymbol)) {
				throw 'Expected interface: ${interfaceType.qname}. Is it missing @:rtti metadata? 2: ${classdef.path}';
			}
			var resolvedInterface = cast(interfaceType, IMXHXInterfaceSymbol);
			resolvedInterfaces.push(resolvedInterface);
		}
		result.interfaces = resolvedInterfaces;
		result.params = params != null ? params : [];
		result.paramNames = classdef.params.copy();
		var fields:Array<IMXHXFieldSymbol> = [];
		fields = fields.concat(classdef.fields.map(field -> createMXHXFieldSymbolForClassField(field, false, classdef, result)));
		fields = fields.concat(classdef.statics.map(field -> createMXHXFieldSymbolForClassField(field, true, classdef, result)));
		result.fields = fields;
		if (classdef.meta != null) {
			result.meta = classdef.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		// result.events = classdef.meta.map(eventMeta -> {
		// 	if (eventMeta.name != ":event") {
		// 		return null;
		// 	}
		// 	if (eventMeta.params.length != 1) {
		// 		return null;
		// 	}
		// 	var eventName = getEventName(eventMeta);
		// 	if (eventName == null) {
		// 		return null;
		// 	}
		// 	var eventTypeQname = getEventType(eventMeta);
		// 	var resolvedType:IMXHXClassSymbol = cast resolveQname(eventTypeQname);
		// 	var result:IMXHXEventSymbol = new MXHXEventSymbol(eventName, resolvedType);
		// 	return result;
		// }).filter(eventSymbol -> eventSymbol != null);
		// result.defaultProperty = getDefaultProperty(classDefinition);
		return result;
	}

	private function createMXHXEnumSymbolForEnumdef(enumdef:Enumdef, params:Array<IMXHXTypeSymbol>):IMXHXEnumSymbol {
		var name = enumdef.path;
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = enumdef.module;
		if (moduleName == null) {
			moduleName = enumdef.path;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXEnumSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		result.doc = enumdef.doc;
		result.file = enumdef.file;
		// result.offsets = {start: pos.min, end: pos.max};
		result.isPrivate = enumdef.isPrivate;
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		result.params = params != null ? params : [];
		result.paramNames = enumdef.params.copy();
		var fields:Array<IMXHXEnumFieldSymbol> = [];
		fields = fields.concat(enumdef.constructors.map(function(constructor:EnumField):IMXHXEnumFieldSymbol {
			var args:Array<IMXHXArgumentSymbol> = null;
			var constructorArgs = constructor.args;
			if (constructorArgs != null) {
				args = constructorArgs.map(function(arg):IMXHXArgumentSymbol {
					var argQname = cTypeToQname(arg.t);
					var type = resolveQname(argQname);
					return new MXHXArgumentSymbol(arg.name, type, arg.opt);
				});
			}
			return new MXHXEnumFieldSymbol(constructor.name, result, args);
		}));
		result.fields = fields;
		if (enumdef.meta != null) {
			result.meta = enumdef.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		return result;
	}

	private function createMXHXEnumSymbolForEnum(resolvedEnum:Enum<Dynamic>, params:Array<IMXHXTypeSymbol>):IMXHXEnumSymbol {
		var name = resolvedEnum.getName();
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = name;
		if (pack.length > 0) {
			moduleName = pack.join(".") + "." + moduleName;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXEnumSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		result.fields = resolvedEnum.getConstructors().map(function(enumConstructorName:String):IMXHXEnumFieldSymbol {
			return new MXHXEnumFieldSymbol(enumConstructorName, result);
		});

		return result;
	}

	private function createMXHXEnumSymbolForAbstractdef(abstractdef:Abstractdef, params:Array<IMXHXTypeSymbol>):IMXHXEnumSymbol {
		var name = abstractdef.path;
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = abstractdef.module;
		if (moduleName == null) {
			moduleName = abstractdef.path;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXEnumSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		result.doc = abstractdef.doc;
		result.file = abstractdef.file;
		// result.offsets = {start: pos.min, end: pos.max};
		result.isPrivate = abstractdef.isPrivate;
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		result.params = params != null ? params : [];
		result.paramNames = abstractdef.params.copy();
		var fields:Array<IMXHXEnumFieldSymbol> = [];
		if (abstractdef.impl != null) {
			fields = fields.concat(abstractdef.impl.statics.map(function(field):IMXHXEnumFieldSymbol {
				var fieldSymbol = new MXHXEnumFieldSymbol(field.name, result);
				fieldSymbol.inlineExpr = field.expr;
				return fieldSymbol;
			}));
		}
		result.fields = fields;
		if (abstractdef.meta != null) {
			result.meta = abstractdef.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		return result;
	}

	private function createMXHXAbstractSymbolForAbstractdef(abstractdef:Abstractdef, params:Array<IMXHXTypeSymbol>):IMXHXAbstractSymbol {
		var name = abstractdef.path;
		var dotIndex = name.lastIndexOf(".");
		var pack:Array<String> = [];
		if (dotIndex != -1) {
			var packString = name.substr(0, dotIndex);
			pack = packString.split(".");
			name = name.substr(dotIndex + 1);
		}
		var moduleName = abstractdef.module;
		if (moduleName == null) {
			moduleName = abstractdef.path;
		}
		var qname = MXHXResolverTools.definitionToQname(name, pack, moduleName,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result = new MXHXAbstractSymbol(name, pack);
		result.qname = qname;
		result.module = moduleName;
		result.doc = abstractdef.doc;
		result.file = abstractdef.file;
		// result.offsets = {start: pos.min, end: pos.max};
		result.isPrivate = abstractdef.isPrivate;
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameToMXHXTypeSymbolLookup.set(qname, result);

		result.params = params != null ? params : [];
		result.paramNames = abstractdef.params.copy();

		var typeQname = cTypeToQname(abstractdef.athis);
		result.type = resolveQname(typeQname);

		if (abstractdef.impl != null) {
			result.impl = createMXHXClassSymbolForClassdef(abstractdef.impl, [], true);
		}

		result.from = abstractdef.from.map(function(from):IMXHXAbstractToOrFromInfo {
			var fromQname:String = null;
			switch (from.t) {
				case CClass(name, params):
					if (StringTools.startsWith(name, from.field + ".")) {
						fromQname = "Dynamic";
					}
				default:
			}
			if (fromQname == null) {
				fromQname = cTypeToQname(from.t);
			}
			var resolvedField:IMXHXFieldSymbol = null;
			if (result.impl != null) {
				resolvedField = Lambda.find(result.impl.fields, fieldSymbol -> fieldSymbol.isStatic && fieldSymbol.name == from.field);
			}
			var resolvedType = resolveQname(fromQname);
			return new MXHXAbstractToOrFromInfo(resolvedField, resolvedType);
		});

		result.to = abstractdef.to.map(function(to):IMXHXAbstractToOrFromInfo {
			var qname = cTypeToQname(to.t);
			var resolvedField:IMXHXFieldSymbol = null;
			if (result.impl != null) {
				resolvedField = Lambda.find(result.impl.fields, fieldSymbol -> fieldSymbol.isStatic && fieldSymbol.name == to.field);
			}
			var resolvedType = resolveQname(qname);
			return new MXHXAbstractToOrFromInfo(resolvedField, resolvedType);
		});

		if (abstractdef.meta != null) {
			result.meta = abstractdef.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		return result;
	}

	private function functionArgsAndRetToQname(args:Array<FunctionArgument>, ret:CType):String {
		var qname = '(';
		for (i in 0...args.length) {
			var arg = args[i];
			if (i > 0) {
				qname += ', ';
			}
			if (arg.opt) {
				qname += '?';
			}
			// qname += arg.name;
			// qname += ':';
			var argTypeName = cTypeToQname(arg.t);
			if (argTypeName == null) {
				argTypeName = "Dynamic";
			}
			qname += argTypeName;
		}
		var retName = cTypeToQname(ret);
		if (retName == null) {
			retName = "Dynamic";
		}
		qname += ') -> ${retName}';
		return qname;
	}

	private function cTypeToQname(ctype:CType):String {
		var ctypeName:String = null;
		var ctypeParams:Array<CType> = null;
		switch (ctype) {
			case CClass(name, params):
				ctypeName = name;
				ctypeParams = params;
			case CAbstract(name, params):
				ctypeName = name;
				ctypeParams = params;
			case CEnum(name, params):
				ctypeName = name;
				ctypeParams = params;
			case CTypedef(name, params):
				ctypeName = name;
				ctypeParams = params;
			case CFunction(args, ret):
				// return "haxe.Function";
				return functionArgsAndRetToQname(args, ret);
			case CDynamic(t):
				return "Dynamic";
			case CAnonymous(fields):
				return "Dynamic";
			case CUnknown:
				return "Dynamic";
			default:
				return null;
		}
		if (ctypeName != null) {
			var qname = ctypeName;
			if (ctypeParams != null && ctypeParams.length > 0) {
				qname += "<";
				for (i in 0...ctypeParams.length) {
					if (i > 0) {
						qname += ",";
					}
					qname += cTypeToQname(ctypeParams[i]);
				}
				qname += ">";
			}
			return qname;
		}
		return null;
	}

	private function createMXHXFieldSymbolForTypeField(fieldName:String, isStatic:Bool, owner:IMXHXTypeSymbol):IMXHXFieldSymbol {
		var result = new MXHXFieldSymbol(fieldName, owner, null, false, true, isStatic);
		return result;
	}

	private function createMXHXFieldSymbolForClassField(field:ClassField, isStatic:Bool, classdef:Classdef, owner:IMXHXTypeSymbol):IMXHXFieldSymbol {
		var resolvedType:IMXHXTypeSymbol = null;
		var typeQname = cTypeToQname(field.type);
		if (typeQname != null) {
			resolvedType = resolveQname(typeQname);
		}
		var isMethod = false;
		var isReadable = false;
		var isWritable = false;
		switch (field.get) {
			case RMethod:
				isMethod = true;
			case RDynamic:
				isMethod = true;
			case RNormal:
				isReadable = true;
			case RCall("accessor"):
				isReadable = true;
			default:
		};
		switch (field.set) {
			case RMethod:
				isMethod = true;
			case RDynamic:
				isMethod = true;
				isWritable = true;
			case RNormal:
				isWritable = true;
			case RCall("accessor"):
				isWritable = true;
			default:
		};
		var isPublic = field.isPublic;
		var isStatic = isStatic;
		var result = new MXHXFieldSymbol(field.name, owner, resolvedType, isMethod, isPublic, isStatic);
		result.isReadable = isReadable;
		result.isWritable = isWritable;
		result.doc = field.doc;
		// result.file = field.file;
		// result.offsets = {start: field.pos.min, end: field.pos.max};
		if (field.meta != null) {
			result.meta = field.meta.map(m -> {
				var params:Array<String> = null;
				if (m.params != null) {
					params = m.params.copy();
				}
				return {name: m.name, params: params};
			});
		} else {
			result.meta = [];
		}
		return result;
	}

	private function qnameToParams(qname:String, startIndex:Int):Array<IMXHXTypeSymbol> {
		var params:Array<IMXHXTypeSymbol> = [];
		var paramsStack = 1;
		var funArgsStack = 0;
		var funRetPending = false;
		var pendingStringStart = startIndex + 1;
		for (i in pendingStringStart...qname.length) {
			var currentChar = qname.charAt(i);
			if (currentChar == "<") {
				paramsStack++;
			} else if (currentChar == ">") {
				if (!funRetPending) {
					paramsStack--;
					if (paramsStack == 0) {
						var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
						if (pendingString.length > 0) {
							params.push(resolveQname(pendingString));
						}
						break;
					}
				} else {
					funRetPending = false;
				}
			} else if (currentChar == "(") {
				funArgsStack++;
			} else if (currentChar == ")") {
				funArgsStack--;
				funRetPending = true;
			} else if (currentChar == "," && funArgsStack == 0 && paramsStack == 1) {
				var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
				params.push(resolveQname(pendingString));
				pendingStringStart = i + 1;
				continue;
			}
		}
		return params;
	}

	private static function splitFunctionTypeQname(qname:String):{args:Array<String>, ret:String} {
		var argStrings:Array<String> = [];
		var retString:String = null;
		var funStack = 1;
		var paramsStack = 0;
		var pendingStringStart = 1;
		for (i in pendingStringStart...qname.length) {
			var currentChar = qname.charAt(i);
			if (currentChar == "<") {
				paramsStack++;
			} else if (currentChar == ">") {
				paramsStack--;
			} else if (currentChar == "(") {
				funStack++;
			} else if (currentChar == ")") {
				funStack--;
				if (funStack == 0) {
					var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
					if (pendingString.length > 0) {
						argStrings.push(pendingString);
					}
					retString = StringTools.trim(qname.substr(qname.indexOf(">", i + 1) + 1));
					break;
				}
			} else if (currentChar == "," && funStack == 1 && paramsStack == 0) {
				var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
				argStrings.push(pendingString);
				pendingStringStart = i + 1;
				continue;
			}
		}
		return {args: argStrings, ret: retString};
	}

	private function resolveParentTag(tagData:IMXHXTagData):IMXHXSymbol {
		var parentTag = tagData.parentTag;
		if (parentTag == null) {
			return null;
		}
		if (parentTag.prefix != tagData.prefix) {
			return null;
		}
		var resolvedParent = resolveTag(parentTag);
		if (resolvedParent != null) {
			return resolvedParent;
		}
		return null;
	}

	private function hasValidPrefix(tag:IMXHXTagData):Bool {
		var prefixMap = tag.compositePrefixMap;
		if (prefixMap == null) {
			return false;
		}
		return prefixMap.containsPrefix(tag.prefix) && prefixMap.containsUri(tag.uri);
	}

	private function resolveTagAsPropertySymbol(tagData:IMXHXTagData):IMXHXFieldSymbol {
		var parentSymbol = resolveParentTag(tagData);
		if (parentSymbol == null || !(parentSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast parentSymbol;
		return MXHXSymbolTools.resolveFieldByName(classSymbol, tagData.shortName);
	}

	private function resolveTagAsEventSymbol(tagData:IMXHXTagData):IMXHXEventSymbol {
		var parentSymbol = resolveParentTag(tagData);
		if (parentSymbol == null || !(parentSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast parentSymbol;
		return MXHXSymbolTools.resolveEventByName(classSymbol, tagData.shortName);
	}

	private function resolveTagAsTypeSymbol(tagData:IMXHXTagData):IMXHXSymbol {
		var prefix = tagData.prefix;
		var uri = tagData.uri;
		var localName = tagData.shortName;

		if (uri != null && manifests.exists(uri)) {
			var mappings = manifests.get(uri);
			if (mappings.exists(localName)) {
				var manifestEntry = mappings.get(localName);
				var qname = manifestEntry.qname;
				var paramNames = manifestEntry.params;
				if (paramNames != null && paramNames.length > 0) {
					var paramQnames:Array<String> = paramNames.map(paramName -> {
						var paramNameAttr = tagData.getAttributeData(paramName);
						if (paramNameAttr == null) {
							return null;
						}
						var itemType:IMXHXTypeSymbol = resolveQname(paramNameAttr.rawValue);
						if (tagData.stateName != null) {
							return null;
						}
						return itemType.qname;
					});
					qname += "<";
					for (i in 0...paramQnames.length) {
						if (i > 0) {
							qname += ",";
						}
						var paramQname = paramQnames[i];
						if (paramQname == null) {
							paramQname = "%";
						}
						qname += paramQname;
					}
					qname += ">";
					return resolveQname(qname);
				}
				var type = resolveQname(qname);
				if (type != null) {
					if ((type is IMXHXEnumSymbol)) {
						var enumSymbol:IMXHXEnumSymbol = cast type;
						if (tagData.stateName == null) {
							return type;
						}
						return Lambda.find(enumSymbol.fields, field -> field.name == tagData.stateName);
					} else {
						if (tagData.stateName != null) {
							return null;
						}
						return type;
					}
				}
			}
		}
		if (tagData.stateName != null) {
			return null;
		}

		if (uri != "*" && !StringTools.endsWith(uri, ".*")) {
			return null;
		}
		var qname = uri.substr(0, uri.length - 1) + localName;
		var qnameType = resolveQname(qname);
		if (qnameType == null) {
			return null;
		}
		return qnameType;
	}

	private static function getDefaultProperty(classdef:Classdef):String {
		var defaultPropertyMeta = Lambda.find(classdef.meta, item -> item.name == META_DEFAULT_XML_PROPERTY
			|| item.name == ":" + META_DEFAULT_XML_PROPERTY);
		if (defaultPropertyMeta == null) {
			return null;
		}
		if (defaultPropertyMeta.params == null || defaultPropertyMeta.params.length != 1) {
			throw 'The @${defaultPropertyMeta.name} meta must have one property name';
		}
		var propertyName = defaultPropertyMeta.params[0];
		if (propertyName == null || !~/^("|').+\1$/.match(propertyName)) {
			throw 'The @${META_DEFAULT_XML_PROPERTY} meta param must be a string';
			return null;
		}
		return propertyName.substring(1, propertyName.length - 1);
	}
}
