package mxhx.resolver.rtti;

import mxhx.manifest.MXHXManifestEntry;
import mxhx.symbols.IMXHXAbstractSymbol;
import haxe.Resource;
import mxhx.symbols.IMXHXClassSymbol;
import mxhx.symbols.IMXHXInterfaceSymbol;
import utest.Assert;
import utest.Test;

class MXHXRttiResolverQnameTest extends Test {
	private var resolver:MXHXRttiResolver;

	public function setup():Void {
		resolver = new MXHXRttiResolver();

		var content = Resource.getString("mxhx-manifest");
		var xml = Xml.parse(content);
		var mappings:Map<String, MXHXManifestEntry> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			mappings.set(xmlName, new MXHXManifestEntry(xmlName, qname));
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);
	}

	public function teardown():Void {
		resolver = null;
	}

	public function testResolveAny():Void {
		var resolved = resolver.resolveQname("Any");
		Assert.notNull(resolved);
		Assert.equals("Any", resolved.qname);
	}

	public function testResolveArray():Void {
		var resolved = resolver.resolveQname("Array");
		Assert.notNull(resolved);
		Assert.equals("Array", resolved.qname);
	}

	public function testResolveBool():Void {
		var resolved = resolver.resolveQname("Bool");
		Assert.notNull(resolved);
		Assert.equals("Bool", resolved.qname);
	}

	public function testResolveStdTypesBool():Void {
		var resolved = resolver.resolveQname("StdTypes.Bool");
		Assert.notNull(resolved);
		Assert.equals("Bool", resolved.qname);
	}

	public function testResolveDynamic():Void {
		var resolved = resolver.resolveQname("Dynamic");
		Assert.equals("Dynamic", resolved.qname);
	}

	public function testResolveEReg():Void {
		var resolved = resolver.resolveQname("EReg");
		Assert.notNull(resolved);
		Assert.equals("EReg", resolved.qname);
	}

	public function testResolveFloat():Void {
		var resolved = resolver.resolveQname("Float");
		Assert.notNull(resolved);
		Assert.equals("Float", resolved.qname);
	}

	public function testResolveStdTypesFloat():Void {
		var resolved = resolver.resolveQname("StdTypes.Float");
		Assert.notNull(resolved);
		Assert.equals("Float", resolved.qname);
	}

	public function testResolveInt():Void {
		var resolved = resolver.resolveQname("Int");
		Assert.notNull(resolved);
		Assert.equals("Int", resolved.qname);
	}

	public function testResolveStdTypesInt():Void {
		var resolved = resolver.resolveQname("StdTypes.Int");
		Assert.notNull(resolved);
		Assert.equals("Int", resolved.qname);
	}

	public function testResolveString():Void {
		var resolved = resolver.resolveQname("String");
		Assert.notNull(resolved);
		Assert.equals("String", resolved.qname);
	}

	public function testResolveUInt():Void {
		var resolved = resolver.resolveQname("UInt");
		Assert.notNull(resolved);
		Assert.equals("UInt", resolved.qname);
	}

	public function testResolveQnameFromLocalClass():Void {
		var resolved = resolver.resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXClassSymbol);
		Assert.equals("fixtures.TestPropertiesClass", resolved.qname);
	}

	public function testResolveQnameFromLocalInterface():Void {
		var resolved = resolver.resolveQname("fixtures.ITestPropertiesInterface");
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXInterfaceSymbol);
		Assert.equals("fixtures.ITestPropertiesInterface", resolved.qname);
	}

	public function testResolveAbstractFrom():Void {
		var resolved = resolver.resolveQname("fixtures.TestAbstractFrom");
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXAbstractSymbol);
		Assert.equals("fixtures.TestAbstractFrom", resolved.qname);
		var resolvedAbstract:IMXHXAbstractSymbol = cast resolved;
		Assert.notNull(resolvedAbstract.impl);
		Assert.equals("fixtures._TestAbstractFrom.TestAbstractFrom_Impl_", resolvedAbstract.impl.qname);
	}

	public function testResolveAbstractFromModuleType():Void {
		var resolved = resolver.resolveQname("fixtures.TestAbstractFromModuleType");
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXAbstractSymbol);
		Assert.equals("fixtures.TestAbstractFromModuleType", resolved.qname);
		var resolvedAbstract:IMXHXAbstractSymbol = cast resolved;
		Assert.notNull(resolvedAbstract.impl);
		Assert.equals("fixtures._TestAbstractFromModuleType.TestAbstractFromModuleType_Impl_", resolvedAbstract.impl.qname);
		var fromFloat = Lambda.find(resolvedAbstract.impl.fields, field -> field.name == "fromFloat");
		Assert.notNull(fromFloat);
		Assert.equals("fromFloat", fromFloat.name);
	}
}
