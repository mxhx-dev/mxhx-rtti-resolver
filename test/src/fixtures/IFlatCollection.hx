package fixtures;

interface IFlatCollection<U> {
	public function get(index:Int):U;
	public function set(index:Int, item:U):Void;
}
