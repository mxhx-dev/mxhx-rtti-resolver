package mxhx.resolver.rtti;

import haxe.Resource;
import mxhx.manifest.MXHXManifestEntry;
import mxhx.parser.MXHXParser;
import mxhx.symbols.IMXHXTypeSymbol;
import utest.Assert;
import utest.Test;

class MXHXRttiResolverTagTypeTest extends Test {
	private static function getOffsetTag(source:String, offset:Int):IMXHXTagData {
		var parser = new MXHXParser(source, "source.mxhx");
		var mxhxData = parser.parse();
		return mxhxData.findTagOrSurroundingTagContainingOffset(offset);
	}

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

	public function testResolveRootTag():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:tests="https://ns.mxhx.dev/2024/tests"/>
		', 15);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("fixtures.TestClass1", typeSymbol.qname);
	}

	public function testResolveRootTagObject():Void {
		var offsetTag = getOffsetTag('
			<mx:Object xmlns:mx="https://ns.mxhx.dev/2024/basic"/>
		', 10);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Any", typeSymbol.qname);
	}

	public function testResolveDeclarationsArray():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Array type="Float"/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Array<Float>", typeSymbol.qname);
		Assert.notNull(typeSymbol.paramNames);
		Assert.equals(1, typeSymbol.paramNames.length);
		Assert.equals("T", typeSymbol.paramNames[0]);
	}

	public function testResolveDeclarationsBool():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Bool/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Bool", typeSymbol.qname);
	}

	public function testResolveDeclarationsDate():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Date/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Date", typeSymbol.qname);
	}

	public function testResolveDeclarationsEReg():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:EReg/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("EReg", typeSymbol.qname);
	}

	public function testResolveDeclarationsFloat():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Float/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Float", typeSymbol.qname);
	}

	public function testResolveDeclarationsFunction():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Function/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("haxe.Function", typeSymbol.qname);
	}

	public function testResolveDeclarationsInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Int/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Int", typeSymbol.qname);
	}

	public function testResolveDeclarationsString():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:String/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("String", typeSymbol.qname);
	}

	public function testResolveDeclarationsStruct():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Struct/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		// TODO: should this have a type parameter?
		Assert.equals("Dynamic", typeSymbol.qname);
	}

	public function testResolveDeclarationsUInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:UInt/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("UInt", typeSymbol.qname);
	}

	public function testResolveDeclarationsXml():Void {
		var offsetTag = getOffsetTag('
			<tests:TestClass1 xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<mx:Declarations>
					<mx:Xml/>
				</mx:Declarations>
			</tests:TestClass1>
		', 142);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Xml", typeSymbol.qname);
	}
}
