package keyboard.events {
	import flash.events.Event;
	
	// HangleUnicodeComposer 에서 사용하는 이벤트
	public class HangleTextEvent extends Event {
		static public const UPDATE:String = "update";	// 조합된 문자열이 수정되었을 경우 알림
		static public const LIMITED:String = "limited";	// 글자수가 지정한(restrict) 수를 넘어설 경우 알림
		static public const ERROR:String = "error";		// 에러 발생시
		public var string:String = "";					// 완성된 문자열
		
		// 이벤트 생성자
		public function HangleTextEvent(type:String,stringData:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			string = stringData;
		}
		
		override public function clone():Event {
			return new HangleTextEvent(type, string, bubbles, cancelable);
		}
		
		override public function toString():String {
			return type + " " + string;
		}
	}
}