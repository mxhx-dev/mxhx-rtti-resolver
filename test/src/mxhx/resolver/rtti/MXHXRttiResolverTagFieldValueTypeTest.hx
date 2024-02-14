package mxhx.resolver.rtti;

import haxe.Resource;
import mxhx.parser.MXHXParser;
import mxhx.resolver.IMXHXClassSymbol;
import mxhx.resolver.IMXHXEnumFieldSymbol;
import mxhx.resolver.IMXHXEnumSymbol;
import utest.Assert;
import utest.Test;

class MXHXRttiResolverTagFieldValueTypeTest extends Test {
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
		var mappings:Map<String, String> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			mappings.set(xmlName, qname);
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);
	}

	public function teardown():Void {
		resolver = null;
	}

	public function testResolveFieldValueTypeAny():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:any>
					<mx:Float/>
				</tests:any>
			</tests:TestPropertiesClass>
		', 146);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		// the field is typed as Any, but the value is more specific
		Assert.equals("Float", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeArray():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:array>
					<mx:Array type="String"/>
				</tests:array>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Array<String>", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeBool():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:boolean>
					<mx:Bool/>
				</tests:boolean>
			</tests:TestPropertiesClass>
		', 150);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Bool", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeClass():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:type>
					<mx:Class>Float</mx:Class>
				</tests:type>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		// TODO: should this have a type parameter?
		Assert.equals("Class", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeDate():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:date>
					<mx:Date/>
				</tests:date>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Date", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeDynamic():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		// TODO: should this have a type parameter?
		Assert.equals("Dynamic", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeEReg():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:ereg>
					<mx:EReg/>
				</tests:ereg>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("EReg", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeFloat():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:float>
					<mx:Float/>
				</tests:float>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Float", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeFunction():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:func>
					<mx:Function/>
				</tests:func>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("haxe.Function", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeFunctionSignature():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:funcTyped>
					<mx:Function/>
				</tests:funcTyped>
			</tests:TestPropertiesClass>
		', 152);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("haxe.Function", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:integer>
					<mx:Int/>
				</tests:integer>
			</tests:TestPropertiesClass>
		', 150);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Int", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeString():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:string>
					<mx:String/>
				</tests:string>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("String", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeStruct():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		// TODO: should this have a type parameter?
		Assert.equals("Dynamic", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeUInt():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:unsignedInteger>
					<mx:UInt/>
				</tests:unsignedInteger>
			</tests:TestPropertiesClass>
		', 158);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("UInt", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeXml():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:xml>
					<mx:Xml/>
				</tests:xml>
			</tests:TestPropertiesClass>
		', 146);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Xml", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeAbstractEnumValueEmpty():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:abstractEnumValue>
					<tests:TestPropertyAbstractEnum/>
				</tests:abstractEnumValue>
			</tests:TestPropertiesClass>
		', 163);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("fixtures.TestPropertyAbstractEnum", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeAbstractEnumFieldValue():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:abstractEnumValue>
					<tests:TestPropertyAbstractEnum.Value1/>
				</tests:abstractEnumValue>
			</tests:TestPropertiesClass>
		', 188);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXEnumFieldSymbol);
		var fieldSymbol:IMXHXEnumFieldSymbol = cast resolved;
		Assert.equals("Value1", fieldSymbol.name);
		Assert.notNull(fieldSymbol.parent);
		Assert.equals("fixtures.TestPropertyAbstractEnum", fieldSymbol.parent.qname);
	}

	public function testResolveFieldValueTypeEnumValueEmpty():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:enumValue>
					<tests:TestPropertyEnum/>
				</tests:enumValue>
			</tests:TestPropertiesClass>
		', 155);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXEnumSymbol);
		var typeSymbol:IMXHXEnumSymbol = cast resolved;
		Assert.equals("fixtures.TestPropertyEnum", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeEnumFieldValue():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:enumValue>
					<tests:TestPropertyEnum.Value1/>
				</tests:enumValue>
			</tests:TestPropertiesClass>
		', 172);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXEnumFieldSymbol);
		var fieldSymbol:IMXHXEnumFieldSymbol = cast resolved;
		Assert.equals("Value1", fieldSymbol.name);
		Assert.notNull(fieldSymbol.parent);
		Assert.equals("fixtures.TestPropertyEnum", fieldSymbol.parent.qname);
	}

	public function testResolveFieldValueTypeComplexEnumValue():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:complexEnum>
					<tests:TestComplexEnum.Two a="hello" b="123.4"/>
				</tests:complexEnum>
			</tests:TestPropertiesClass>
		', 173);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXEnumFieldSymbol);
		var fieldSymbol:IMXHXEnumFieldSymbol = cast resolved;
		Assert.equals("Two", fieldSymbol.name);
		Assert.notNull(fieldSymbol.parent);
		Assert.equals("fixtures.TestComplexEnum", fieldSymbol.parent.qname);
		var args = fieldSymbol.args;
		Assert.equals(2, args.length);
		Assert.equals("a", args[0].name);
		Assert.isFalse(args[0].optional);
		Assert.notNull(args[0].type);
		Assert.equals("String", args[0].type.qname);
		Assert.equals("b", args[1].name);
		Assert.isTrue(args[1].optional);
		Assert.notNull(args[1].type);
		Assert.equals("Null<Float>", args[1].type.qname);
	}

	public function testResolveFieldValueTypeNull():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:canBeNull>
					<mx:Float/>
				</tests:canBeNull>
			</tests:TestPropertiesClass>
		', 155);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXTypeSymbol);
		var typeSymbol:IMXHXTypeSymbol = cast resolved;
		Assert.equals("Float", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeStrict():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictlyTyped>
					<tests:TestPropertiesClass/>
				</tests:strictlyTyped>
			</tests:TestPropertiesClass>
		', 159);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXClassSymbol);
		var typeSymbol:IMXHXClassSymbol = cast resolved;
		Assert.equals("fixtures.TestPropertiesClass", typeSymbol.qname);
	}

	public function testResolveFieldValueTypeStrictInterface():Void {
		var offsetTag = getOffsetTag('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictInterface>
					<tests:TestPropertiesClass/>
				</tests:strictInterface>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(offsetTag);

		var resolved = resolver.resolveTag(offsetTag);
		Assert.notNull(resolved);
		Assert.isOfType(resolved, IMXHXClassSymbol);
		var typeSymbol:IMXHXClassSymbol = cast resolved;
		Assert.equals("fixtures.TestPropertiesClass", typeSymbol.qname);
	}
}
