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

import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.PositionTools;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.BaseType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.DefType;
import haxe.macro.Type.EnumField;
import haxe.macro.Type.EnumType;
import haxe.macro.Type.ModuleType;

/**
	Generates RTTI data for certain types, like abstracts, enums, and certain
	native classes, because the compiler skips them, but their data is still
	needed by `MXHXRttiResolver`.
**/
@:noCompletion
@:dox(hide)
class MXHXRttiGenerator {
	#if macro
	public static function generate():Void {
		Context.onAfterTyping((modules:Array<ModuleType>) -> {
			final isFlash = Context.defined("flash");
			var hasMXHXRttiAbstracts = try {
				Context.getType("mxhx.resolver.rtti._internal.MXHXRttiAbstracts");
				true;
			} catch (e:Dynamic) {
				false;
			}
			var rttiData:Array<Xml> = [];
			var abstractFromFields:Array<Field> = [];
			for (module in modules) {
				switch (module) {
					case TClassDecl(c):
						if (isFlash) {
							var classType = c.get();
							if (classType.name == "MXHXRttiAbstracts"
								&& classType.pack.length == 4
								&& classType.pack[0] == "mxhx"
								&& classType.pack[1] == "resolver"
								&& classType.pack[2] == "rtti"
								&& classType.pack[3] == "_internal") {
								continue;
							}
							if (classType.pack.length > 0 && classType.pack[0] == "flash" && classType.meta.has(":rtti")) {
								var classRtti = createRttiForClassType(classType, []);
								rttiData.push(classRtti);
							}
						}
					case TAbstract(a):
						var abstractType = a.get();
						if (abstractType.meta.has(":rtti")) {
							var abstractRtti = createRttiForAbstractType(abstractType, []);
							rttiData.push(abstractRtti);
							if (!hasMXHXRttiAbstracts) {
								createFromFieldsForAbstractType(abstractType, abstractFromFields);
							}
						}
					case TEnumDecl(e):
						var enumType = e.get();
						if (enumType.meta.has(":rtti")) {
							var enumRtti = createRttiForEnumType(enumType, []);
							rttiData.push(enumRtti);
						}
					case TTypeDecl(t):
						var defType = t.get();
						if (defType.meta.has(":rtti")) {
							var defRtti = createRttiForDefType(defType, []);
							rttiData.push(defRtti);
						}
					default:
				}
			}
			for (rtti in rttiData) {
				var bytes = Bytes.ofString(Std.string(rtti));
				Context.addResource('__mxhxRtti_${rtti.get("path")}', bytes);
			}
			if (!hasMXHXRttiAbstracts) {
				var rttiAbstracts:TypeDefinition = {
					name: "MXHXRttiAbstracts",
					pack: ["mxhx", "resolver", "rtti", "_internal"],
					pos: Context.currentPos(),
					kind: TDClass(),
					fields: abstractFromFields
				};
				Context.defineType(rttiAbstracts);
			}
		});
	}

	private static function createFromFieldsForAbstractType(abstractType:AbstractType, fields:Array<Field>):Void {
		if (abstractType.impl == null) {
			return;
		}
		var statics = abstractType.impl.get().statics.get();
		for (staticField in statics) {
			switch (staticField.kind) {
				case FMethod(MethNormal):
					if (!staticField.meta.has(":from")) {
						continue;
					}
					switch (staticField.type) {
						case TFun(args, ret):
							var fieldName = abstractType.name + "___" + staticField.name;
							if (abstractType.pack.length > 0) {
								fieldName = abstractType.pack.join("_") + "__" + fieldName;
							}
							// we'll try to keep the arg and return types the
							// same, but sometimes they don't resolve because
							// the imports are aliased, or the method has type
							// parameters, so include a fall back to Dynamic.
							var complexRet:ComplexType = Context.toComplexType(ret);
							try {
								var resolvedType = Context.resolveType(complexRet, Context.currentPos());
								if (resolvedType == null) {
									complexRet = TPath({pack: [], name: "Dynamic"});
								}
							} catch (e:Dynamic) {
								complexRet = TPath({pack: [], name: "Dynamic"});
							}
							var complexArgs:Array<FunctionArg> = args.map(function(arg):FunctionArg {
								var complexArg = Context.toComplexType(arg.t);
								try {
									var resolvedType = Context.resolveType(complexArg, Context.currentPos());
									if (resolvedType == null) {
										complexArg = TPath({pack: [], name: "Dynamic"});
									}
								} catch (e:Dynamic) {
									complexArg = TPath({pack: [], name: "Dynamic"});
								}
								return {
									name: arg.name,
									opt: arg.opt,
									type: complexArg
								}
							});
							var qname = MXHXResolverTools.definitionToQname(abstractType.name, abstractType.pack, abstractType.module);
							var methodPath = qname.split(".").concat([staticField.name]);
							var fun:Function = {
								args: complexArgs,
								ret: complexRet,
								expr: macro return @:privateAccess $p{methodPath}($i{args[0].name})
							}
							fields.push({
								name: fieldName,
								pos: Context.currentPos(),
								kind: FFun(fun),
								access: [APublic, AStatic],
								meta: [
									{
										name: ":noCompletion",
										pos: Context.currentPos(),
									}
								]
							});
						default:
					}
				default:
			}
		}
	}
	#end

	private static function isInPackage(pack:Array<String>, packageName:String, recursive:Bool):Bool {
		if (packageName.length == 0) {
			if (recursive) {
				return true;
			}
			return pack.length == 0;
		}
		var packageNameToCheck = pack.join(".");
		if (recursive) {
			return packageName == packageNameToCheck || StringTools.startsWith(packageNameToCheck, packageName + ".");
		}
		return packageName == packageNameToCheck;
	}

	private static function createRttiForType(type:haxe.macro.Type):Xml {
		return switch (type) {
			case TAbstract(t, params):
				createRttiForAbstractType(t.get(), params);
			case TEnum(t, params):
				createRttiForEnumType(t.get(), params);
			case TType(t, params):
				createRttiForDefType(t.get(), params);
			case TInst(t, params):
				createRttiForClassType(t.get(), params);
			default: null;
		}
	}

	private static function createRttiForAbstractType(abstractType:AbstractType, params:Array<haxe.macro.Type>):Xml {
		var rootElement = Xml.createElement("abstract");
		addBasicAttributes(abstractType, params, rootElement);
		addDoc(abstractType, rootElement);
		addMetadata(abstractType, rootElement);

		var fromElement = Xml.createElement("from");
		for (from in abstractType.from) {
			var icastElement = Xml.createElement("icast");
			addTypeElement(from.t, icastElement);
			if (from.field != null) {
				icastElement.set("field", from.field.name);
			}
			fromElement.addChild(icastElement);
		}
		rootElement.addChild(fromElement);

		var toElement = Xml.createElement("to");
		for (to in abstractType.to) {
			var icastElement = Xml.createElement("icast");
			addTypeElement(to.t, icastElement);
			if (to.field != null) {
				icastElement.set("field", to.field.name);
			}
			toElement.addChild(icastElement);
		}
		rootElement.addChild(toElement);

		var thisElement = Xml.createElement("this");
		addTypeElement(abstractType.type, thisElement);
		rootElement.addChild(thisElement);

		if (abstractType.impl != null) {
			var implElement = Xml.createElement("impl");
			var classType = abstractType.impl.get();
			implElement.addChild(createRttiForClassType(classType, []));
			rootElement.addChild(implElement);
		}

		return rootElement;
	}

	private static function createRttiForEnumType(enumType:EnumType, params:Array<haxe.macro.Type>):Xml {
		var rootElement = Xml.createElement("enum");
		addBasicAttributes(enumType, params, rootElement);
		addDoc(enumType, rootElement);
		addMetadata(enumType, rootElement);
		for (construct => enumField in enumType.constructs) {
			addEnumField(enumField, rootElement);
		}
		return rootElement;
	}

	private static function createRttiForDefType(defType:DefType, params:Array<haxe.macro.Type>):Xml {
		var rootElement = Xml.createElement("typedef");
		addBasicAttributes(defType, params, rootElement);
		addDoc(defType, rootElement);
		addMetadata(defType, rootElement);
		addTypeElement(defType.type, rootElement);
		return rootElement;
	}

	private static function createRttiForClassType(classType:ClassType, params:Array<haxe.macro.Type>):Xml {
		var rootElement = Xml.createElement("class");
		addBasicAttributes(classType, params, rootElement);
		if (classType.isFinal) {
			rootElement.set("final", "1");
		}
		if (classType.superClass != null) {
			var superClassType = classType.superClass.t.get();
			var superClassPath = baseTypeToPath(superClassType);
			var extendsElement = Xml.createElement("extends");
			extendsElement.set("path", superClassPath);
			rootElement.addChild(extendsElement);
		}
		// if (classType.isAbstract) {
		// 	rootElement.set("abstract", "1");
		// }
		if (classType.isInterface) {
			rootElement.set("interface", "1");
		}
		addDoc(classType, rootElement);
		addMetadata(classType, rootElement);
		for (field in classType.fields.get()) {
			addClassField(field, false, rootElement);
		}
		for (field in classType.statics.get()) {
			addClassField(field, true, rootElement);
		}
		return rootElement;
	}

	private static function addBasicAttributes(baseType:BaseType, params:Array<haxe.macro.Type>, parentElement:Xml):Void {
		var path = baseTypeToPath(baseType);
		parentElement.set("path", path);
		// not added for rtti
		// parentElement.set("file", PositionTools.getInfos(baseType.pos).file);
		if (path != baseType.module) {
			parentElement.set("module", baseType.module);
		}
		parentElement.set("params", paramsToString(params));
		if (baseType.isExtern) {
			parentElement.set("extern", "1");
		}
		if (baseType.isPrivate) {
			parentElement.set("private", "1");
		}
	}

	private static function addDoc(baseType:BaseType, parentElement:Xml):Void {
		if (baseType.doc == null) {
			return;
		}
		// not added for rtti
		// var haxe_docElement = Xml.createElement("haxe_doc");
		// var haxe_docCData = Xml.createCData(baseType.doc);
		// haxe_docElement.addChild(haxe_docCData);
		// parentElement.addChild(haxe_docElement);
	}

	private static function addMetadataEntries(metadataEntries:Array<MetadataEntry>, parentElement:Xml):Void {
		if (metadataEntries.length == 0) {
			return;
		}
		var metaElement = createRttiForMetadata(metadataEntries);
		parentElement.addChild(metaElement);
	}

	private static function addMetadata(baseType:BaseType, parentElement:Xml):Void {
		var metadataEntries:Array<MetadataEntry> = baseType.meta.get();
		addMetadataEntries(metadataEntries, parentElement);
	}

	private static function addEnumField(enumField:EnumField, parentElement:Xml):Void {
		var enumFieldElement = Xml.createElement(enumField.name);
		switch (enumField.type) {
			case TFun(args, ret):
				addFunctionArgsForTypeElement(args, enumFieldElement);
			default:
		}
		addMetadataEntries(enumField.meta.get(), enumFieldElement);
		parentElement.addChild(enumFieldElement);
	}

	private static function addClassField(classField:ClassField, isStatic:Bool, parentElement:Xml):Void {
		var classFieldElement = Xml.createElement(classField.name);
		if (classField.isPublic) {
			classFieldElement.set("public", "1");
		}
		if (classField.isExtern) {
			classFieldElement.set("extern", "1");
		}
		// if (classField.isAbstract) {
		// 	classFieldElement.set("abstract", "1");
		// }
		if (isStatic) {
			classFieldElement.set("static", "1");
		}
		#if macro
		classFieldElement.set("line", Std.string(PositionTools.toLocation(classField.pos).range.start.line));
		#end
		switch (classField.kind) {
			case FVar(read, write):
				switch (read) {
					case AccNormal:
						// there is no get attribute for normal
					case AccNo:
						classFieldElement.set("get", "null");
					case AccNever:
						// the Haxe compiler seems to convert never to null
						classFieldElement.set("set", "null");
					case AccCall:
						classFieldElement.set("get", "accessor");
					case AccInline:
						classFieldElement.set("get", "inline");

						var metadataEntries:Array<MetadataEntry> = classField.meta.get();
						var valueEntry = Lambda.find(metadataEntries, metadataEntry -> metadataEntry.name == ":value");
						if (valueEntry != null && valueEntry.params != null && valueEntry.params.length > 0) {
							var valueParam = valueEntry.params[0];
							var eString:String = "";
							var current = valueParam;
							while (current != null) {
								switch (current.expr) {
									case ECast(e, t):
										eString += "cast ";
										current = e;
									#if (haxe_ver >= 4.3)
									case EConst(CInt(v, s)):
									#else
									case EConst(CInt(v)):
									#end
										eString += Std.string(v);
										current = null;
									#if (haxe_ver >= 4.3)
									case EConst(CFloat(f, s)):
									#else
									case EConst(CFloat(f)):
									#end
										eString += Std.string(f);
										current = null;
									case EConst(CString(s, DoubleQuotes)):
										eString += '"${s}"';
										current = null;
									case EConst(CString(s, SingleQuotes)):
										eString += '\'${s}\'';
										current = null;
									default:
										eString = null;
										current = null;
								}
							}
							if (eString != null) {
								classFieldElement.set("expr", eString);
							}
						}
					case AccRequire(r, msg):
						// this field doesn't seem to be supported
						// and should be safe to ignore
						return;
					case AccCtor:
						// should be safe to ignore because it is accessible
						// only from the constructor
						return;
					default:
						throw 'Unknown read: $read';
				}
				switch (write) {
					case AccNormal:
						// there is no set attribute for normal
					case AccNo:
						classFieldElement.set("set", "null");
					case AccNever:
						// the Haxe compiler seems to convert never to null
						classFieldElement.set("set", "null");
					case AccCall:
						classFieldElement.set("set", "accessor");
					case AccInline:
						classFieldElement.set("set", "inline");
					case AccRequire(r, msg):
						// this field doesn't seem to be supported
						// and should be safe to ignore
						return;
					case AccCtor:
						// should be safe to ignore because it is accessible
						// only from the constructor
						return;
					default:
						throw 'Unknown write: $write';
				}
			case FMethod(k):
				classFieldElement.set("set", "method");
		}
		addTypeElement(classField.type, classFieldElement);
		addMetadataEntries(classField.meta.get(), classFieldElement);
		parentElement.addChild(classFieldElement);
	}

	private static function createRttiForMetadata(metadataEntries:Array<MetadataEntry>):Xml {
		var metaElement = Xml.createElement("meta");
		for (metadataEntry in metadataEntries) {
			var mElement = Xml.createElement("m");
			mElement.set("n", metadataEntry.name);
			if (metadataEntry.params != null) {
				for (param in metadataEntry.params) {
					#if (haxe_ver < 4.2)
					var exprAsString = switch (param.expr) {
						case EConst(CString(s, kind)):
							switch (kind) {
								case DoubleQuotes:
									'"$s"';
								case SingleQuotes:
									'\'$s\'';
							}
						default:
							// apparently, this didn't work for string constants
							// prior to Haxe 4.2
							ExprTools.toString({expr: param.expr, pos: null});
					}
					#else
					var exprAsString = ExprTools.toString({expr: param.expr, pos: null});
					#end

					var eElement = Xml.createElement("e");
					var pcData = Xml.createPCData(exprAsString);
					eElement.addChild(pcData);
					mElement.addChild(eElement);
				}
			}
			metaElement.addChild(mElement);
		}
		return metaElement;
	}

	private static function addTypeElement(type:haxe.macro.Type, parentElement:Xml):Void {
		while (type != null) {
			switch (type) {
				case TEnum(t, params):
					// TODO: add params
					var typeElement = Xml.createElement("e");
					typeElement.set("path", baseTypeToPath(t.get()));
					for (param in params) {
						addTypeElement(param, typeElement);
					}
					parentElement.addChild(typeElement);
					return;
				case TInst(t, params):
					// TODO: add params
					var typeElement = Xml.createElement("c");
					typeElement.set("path", baseTypeToPath(t.get()));
					for (param in params) {
						addTypeElement(param, typeElement);
					}
					parentElement.addChild(typeElement);
					return;
				case TType(t, params):
					// TODO: add params
					var typeElement = Xml.createElement("t");
					typeElement.set("path", baseTypeToPath(t.get()));
					for (param in params) {
						addTypeElement(param, typeElement);
					}
					parentElement.addChild(typeElement);
					return;
				case TAbstract(t, params):
					// TODO: add params
					var typeElement = Xml.createElement("x");
					typeElement.set("path", baseTypeToPath(t.get()));
					for (param in params) {
						addTypeElement(param, typeElement);
					}
					parentElement.addChild(typeElement);
					return;
				case TFun(args, ret):
					var typeElement = Xml.createElement("f");
					addFunctionArgsForTypeElement(args, typeElement);
					addTypeElement(ret, typeElement);
					parentElement.addChild(typeElement);
					return;
				case TAnonymous(a):
					// TODO: add fields
					var typeElement = Xml.createElement("a");
					parentElement.addChild(typeElement);
					return;
				case TDynamic(t):
					// TODO: add type
					var typeElement = Xml.createElement("d");
					parentElement.addChild(typeElement);
					return;
				case TLazy(f):
					type = f();
				case TMono(t):
					return;
				default:
					throw "Missing handler for type: " + type;
			}
		}
	}

	private static function addFunctionArgsForTypeElement(args:Array<{name:String, opt:Bool, t:haxe.macro.Type}>, parentElement:Xml):Void {
		var argsString = "";
		for (i in 0...args.length) {
			if (i > 0) {
				argsString += ":";
			}
			var arg = args[i];
			if (arg.opt) {
				argsString += "?";
			}
			argsString += arg.name;
			addTypeElement(arg.t, parentElement);
		}
		parentElement.set("a", argsString);
	}

	private static function baseTypeToPath(b:BaseType):String {
		var path = b.name;
		if (b.pack != null && b.pack.length > 0) {
			path = b.pack.join(".") + "." + b.name;
		}
		return path;
	}

	private static function paramsToString(params:Array<haxe.macro.Type>):String {
		var result = "";
		for (i in 0...params.length) {
			if (i > 0) {
				result += ":";
			}
			var param = params[i];
			switch (param) {
				default:
					result += "XYZ";
			}
		}
		return result;
	}
}
