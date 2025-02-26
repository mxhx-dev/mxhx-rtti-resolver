package mxhx.resolver.rtti;

import haxe.Resource;
import mxhx.manifest.MXHXManifestEntry;
import mxhx.parser.MXHXParser;
import mxhx.symbols.IMXHXAbstractSymbol;
import mxhx.symbols.IMXHXClassSymbol;
import mxhx.symbols.IMXHXEnumSymbol;
import mxhx.symbols.IMXHXFieldSymbol;
import mxhx.symbols.IMXHXFunctionTypeSymbol;
import mxhx.symbols.IMXHXInterfaceSymbol;
import utest.Assert;
import utest.Test;

class MXHXRttiResolverTagFieldTypeTest extends Test {
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

	public function testResolveFieldTypeAny():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:any>
					<mx:Float/>
				</tests:any>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Any", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeArray():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:array>
					<mx:Array/>
				</tests:array>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("Array<String>", fieldSymbol.type.qname);
		Assert.notNull(fieldSymbol.type.paramNames);
		Assert.equals(1, fieldSymbol.type.paramNames.length);
		Assert.equals("T", fieldSymbol.type.paramNames[0]);
	}

	public function testResolveFieldTypeBool():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:boolean>
					<mx:Bool/>
				</tests:boolean>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Bool", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeClass():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:type>
					<mx:Class>Float</mx:Class>
				</tests:type>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Class<Dynamic>", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeDate():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:date>
					<mx:Date/>
				</tests:date>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("Date", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeDynamic():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Dynamic", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeEReg():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:ereg>
					<mx:EReg/>
				</tests:ereg>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("EReg", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeFloat():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:float>
					<mx:Float/>
				</tests:float>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Float", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeFunction():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:func>
					<mx:Function/>
				</tests:func>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("haxe.Function", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeFunctionSignature():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:funcTyped>
					<mx:Function/>
				</tests:funcTyped>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXFunctionTypeSymbol);
		Assert.equals("() -> Void", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:integer>
					<mx:Int/>
				</tests:integer>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Int", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeString():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:string>
					<mx:String/>
				</tests:string>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("String", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeStruct():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Dynamic", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeUInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:unsignedInteger>
					<mx:UInt/>
				</tests:unsignedInteger>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("UInt", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeXml():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:xml>
					<mx:Xml/>
				</tests:xml>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("Xml", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeAbstractEnumValue():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:abstractEnumValue>
					<tests:TestPropertyAbstractEnum/>
				</tests:abstractEnumValue>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXEnumSymbol);
		Assert.equals("fixtures.TestPropertyAbstractEnum", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeEnumValue():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:enumValue>
					<tests:TestPropertyEnum/>
				</tests:enumValue>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXEnumSymbol);
		Assert.equals("fixtures.TestPropertyEnum", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeNull():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:canBeNull>
					<tests:Float/>
				</tests:canBeNull>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXAbstractSymbol);
		Assert.equals("Null<Float>", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeStrict():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictlyTyped>
					<tests:TestPropertiesClass/>
				</tests:strictlyTyped>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXClassSymbol);
		Assert.equals("fixtures.TestPropertiesClass", fieldSymbol.type.qname);
	}

	public function testResolveFieldTypeStrictInterface():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictInterface>
					<tests:TestPropertiesClass/>
				</tests:strictInterface>
			</tests:TestPropertiesClass>
		', 132);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXFieldSymbol);
		var fieldSymbol:IMXHXFieldSymbol = cast resolved;
		Assert.notNull(fieldSymbol.type);
		Assert.isOfType(fieldSymbol.type, IMXHXInterfaceSymbol);
		Assert.equals("fixtures.ITestPropertiesInterface", fieldSymbol.type.qname);
	}
}
