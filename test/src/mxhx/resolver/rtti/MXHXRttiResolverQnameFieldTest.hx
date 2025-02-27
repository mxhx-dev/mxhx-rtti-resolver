package mxhx.resolver.rtti;

import mxhx.manifest.MXHXManifestEntry;
import haxe.Resource;
import mxhx.symbols.IMXHXAbstractSymbol;
import mxhx.symbols.IMXHXClassSymbol;
import mxhx.symbols.IMXHXEnumSymbol;
import mxhx.symbols.IMXHXFunctionTypeSymbol;
import mxhx.symbols.IMXHXInterfaceSymbol;
import utest.Assert;
import utest.Test;

class MXHXRttiResolverQnameFieldTest extends Test {
	private var resolver:MXHXRttiResolver;

	public function setup():Void {
		resolver = new MXHXRttiResolver();

		var content = Resource.getString("mxhx-manifest");
		var xml = Xml.parse(content);
		var mappings:Map<String, MXHXManifestEntry> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			var params:Array<String> = null;
			if (componentXml.exists("params")) {
				params = componentXml.get("params").split(",");
			}
			mappings.set(xmlName, new MXHXManifestEntry(xmlName, qname, params));
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);
	}

	public function teardown():Void {
		resolver = null;
	}

	public function testResolveAnyField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "any");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Any", resolvedField.type.qname);
	}

	public function testResolveArrayField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "array");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("Array<String>", resolvedField.type.qname);

		Assert.notNull(resolvedField.type.params);
		Assert.equals(1, resolvedField.type.params.length);
		Assert.equals("String", resolvedField.type.params[0].qname);

		Assert.notNull(resolvedField.type.paramNames);
		Assert.equals(1, resolvedField.type.paramNames.length);
		Assert.equals("T", resolvedField.type.paramNames[0]);
	}

	public function testResolveBoolField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "boolean");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Bool", resolvedField.type.qname);
	}

	public function testResolveClassField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "type");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Class<Dynamic>", resolvedField.type.qname);
	}

	public function testResolveDateField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "date");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("Date", resolvedField.type.qname);
	}

	public function testResolveDynamicField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "struct");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Dynamic", resolvedField.type.qname);
	}

	public function testResolveERegField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "ereg");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("EReg", resolvedField.type.qname);
	}

	public function testResolveFloatField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "float");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Float", resolvedField.type.qname);
	}

	public function testResolveFunctionConstraintField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "func");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("haxe.Function", resolvedField.type.qname);
	}

	public function testResolveFunctionSignatureField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "funcTyped");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXFunctionTypeSymbol);
		Assert.equals("() -> Void", resolvedField.type.qname);
	}

	public function testResolveIntField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "integer");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Int", resolvedField.type.qname);
	}

	public function testResolveStringField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "string");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("String", resolvedField.type.qname);
	}

	public function testResolveUIntField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "unsignedInteger");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("UInt", resolvedField.type.qname);
	}

	public function testResolveXmlField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "xml");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("Xml", resolvedField.type.qname);
	}

	public function testResolveNullField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "canBeNull");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXAbstractSymbol);
		Assert.equals("Null<Float>", resolvedField.type.qname);
		Assert.notNull(resolvedField.type.params);
		Assert.equals(1, resolvedField.type.params.length);
		Assert.equals("Float", resolvedField.type.params[0].qname);
		Assert.notNull(resolvedField.type.paramNames);
		Assert.equals(1, resolvedField.type.paramNames.length);
		Assert.equals("T", resolvedField.type.paramNames[0]);
	}

	public function testResolveStrictlyTypedField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "strictlyTyped");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("fixtures.TestPropertiesClass", resolvedField.type.qname);
	}

	public function testResolveStrictlyTypedInterfaceField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "strictInterface");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXInterfaceSymbol);
		Assert.equals("fixtures.ITestPropertiesInterface", resolvedField.type.qname);
	}

	public function testResolveAbstractEnumValueField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "abstractEnumValue");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXEnumSymbol);
		Assert.equals("fixtures.TestPropertyAbstractEnum", resolvedField.type.qname);
	}

	public function testResolveEnumValueField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "enumValue");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXEnumSymbol);
		Assert.equals("fixtures.TestPropertyEnum", resolvedField.type.qname);
	}

	public function testResolveClassFromModuleWithDifferentName():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "classFromModuleWithDifferentName");
		Assert.notNull(resolvedField);
		Assert.notNull(resolvedField.type);
		Assert.isOfType(resolvedField.type, IMXHXClassSymbol);
		Assert.equals("fixtures.ModuleWithClassThatHasDifferentName.ThisClassHasADifferentNameThanItsModule", resolvedField.type.qname);
	}

	public function testResolveFieldWithTypeParameter():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.ArrayCollection");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		Assert.notNull(resolvedClass.params);
		Assert.equals(1, resolvedClass.params.length);
		Assert.isNull(resolvedClass.params[0]);
		Assert.notNull(resolvedClass.paramNames);
		Assert.equals(1, resolvedClass.paramNames.length);
		Assert.equals("T", resolvedClass.paramNames[0]);
		var resolvedArrayField = Lambda.find(resolvedClass.fields, field -> field.name == "array");
		Assert.notNull(resolvedArrayField);
		Assert.notNull(resolvedArrayField.type);
		Assert.isOfType(resolvedArrayField.type, IMXHXClassSymbol);
		// TODO: fix the % that should be used only internally
		Assert.equals("Array<%>", resolvedArrayField.type.qname);
		Assert.notNull(resolvedArrayField.type.params);
		Assert.equals(1, resolvedArrayField.type.params.length);
		Assert.isNull(resolvedArrayField.type.params[0]);
		Assert.notNull(resolvedArrayField.type.paramNames);
		Assert.equals(1, resolvedArrayField.type.paramNames.length);
		Assert.equals("T", resolvedArrayField.type.paramNames[0]);

		var resolvedGetField = Lambda.find(resolvedClass.fields, field -> field.name == "get");
		Assert.notNull(resolvedGetField);
		Assert.notNull(resolvedGetField.type);
		Assert.equals("(Int) -> Dynamic", resolvedGetField.type.qname);

		var resolvedSetField = Lambda.find(resolvedClass.fields, field -> field.name == "set");
		Assert.notNull(resolvedSetField);
		Assert.notNull(resolvedSetField.type);
		Assert.equals("(Int, Dynamic) -> Void", resolvedSetField.type.qname);

		Assert.notNull(resolvedClass.interfaces);
		Assert.equals(1, resolvedClass.interfaces.length);

		var interface0 = resolvedClass.interfaces[0];
		Assert.notNull(interface0);
		Assert.isOfType(interface0, IMXHXInterfaceSymbol);
		Assert.equals("fixtures.IFlatCollection<%>", interface0.qname);

		Assert.notNull(interface0.params);
		Assert.equals(1, interface0.params.length);
		Assert.isNull(interface0.params[0]);

		Assert.notNull(interface0.paramNames);
		Assert.equals(1, interface0.paramNames.length);
		Assert.equals("U", interface0.paramNames[0]);
	}

	public function testResolveFieldWithInheritedTypeParameter():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.ArrayCollection<Float>");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		Assert.equals("fixtures.ArrayCollection<Float>", resolvedClass.qname);
		Assert.notNull(resolvedClass.params);
		Assert.equals(1, resolvedClass.params.length);
		Assert.equals("Float", resolvedClass.params[0].qname);
		Assert.notNull(resolvedClass.paramNames);
		Assert.equals(1, resolvedClass.paramNames.length);
		Assert.equals("T", resolvedClass.paramNames[0]);

		var resolvedArrayField = Lambda.find(resolvedClass.fields, field -> field.name == "array");
		Assert.notNull(resolvedArrayField);
		Assert.notNull(resolvedArrayField.type);
		Assert.isOfType(resolvedArrayField.type, IMXHXClassSymbol);
		Assert.equals("Array<Float>", resolvedArrayField.type.qname);
		Assert.notNull(resolvedArrayField.type.params);
		Assert.equals(1, resolvedArrayField.type.params.length);
		Assert.equals("Float", resolvedArrayField.type.params[0].qname);
		Assert.notNull(resolvedArrayField.type.paramNames);
		Assert.equals(1, resolvedArrayField.type.paramNames.length);
		Assert.equals("T", resolvedArrayField.type.paramNames[0]);

		var resolvedGetField = Lambda.find(resolvedClass.fields, field -> field.name == "get");
		Assert.notNull(resolvedGetField);
		Assert.notNull(resolvedGetField.type);
		Assert.equals("(Int) -> Float", resolvedGetField.type.qname);

		var resolvedSetField = Lambda.find(resolvedClass.fields, field -> field.name == "set");
		Assert.notNull(resolvedSetField);
		Assert.notNull(resolvedSetField.type);
		Assert.equals("(Int, Float) -> Void", resolvedSetField.type.qname);

		Assert.notNull(resolvedClass.interfaces);
		Assert.equals(1, resolvedClass.interfaces.length);

		var interface0 = resolvedClass.interfaces[0];
		Assert.notNull(interface0);
		Assert.isOfType(interface0, IMXHXInterfaceSymbol);
		Assert.equals("fixtures.IFlatCollection<Float>", interface0.qname);

		Assert.notNull(interface0.params);
		Assert.equals(1, interface0.params.length);
		Assert.equals("Float", interface0.params[0].qname);

		Assert.notNull(interface0.paramNames);
		Assert.equals(1, interface0.paramNames.length);
		Assert.equals("U", interface0.paramNames[0]);
	}

	public function testResolveMethodField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "testMethod");
		Assert.notNull(resolvedField);
		Assert.isTrue(resolvedField.isMethod);
		Assert.isFalse(resolvedField.isWritable);
	}

	public function testResolveDynamicMethodField():Void {
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolvedClass);
		Assert.isOfType(resolvedClass, IMXHXClassSymbol);
		var resolvedField = Lambda.find(resolvedClass.fields, field -> field.name == "testDynamicMethod");
		Assert.notNull(resolvedField);
		Assert.isTrue(resolvedField.isMethod);
		Assert.isTrue(resolvedField.isWritable);
	}
}
