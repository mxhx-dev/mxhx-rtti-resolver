package fixtures;

@:defaultXmlProperty("array")
class ArrayCollection<T> implements IFlatCollection<T> {
	public function new() {}

	public var array:Array<T>;

	public function get(index:Int):T {
		return null;
	}

	public function set(index:Int, item:T):Void {}
}
