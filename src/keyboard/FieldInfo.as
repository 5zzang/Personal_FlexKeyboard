package keyboard {
	public class FieldInfo {
		public var instant:Array;
		public var complete:String;
		
		
		public function FieldInfo() { 
			instant = new Array(); complete = ""; 
		}
		
		public function copy(instantAry:Array, compString:String):void {
			instant = [];
			instant = instant.concat(instantAry);
			complete = compString;
		}
		
		public function del():void {
			instant = [];
			complete = "";
		}
	}
}