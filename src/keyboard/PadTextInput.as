package keyboard  {
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	
	import mx.controls.TextInput;
	import mx.core.FlexGlobals;
	
	
	public class PadTextInput extends mx.controls.TextInput {
		private var _isPopupMode:Boolean = false;
		
		public function PadTextInput() {
			// 화상 키보드 이벤트 등록
			addEventListener(FocusEvent.FOCUS_IN , onScreenKeyboard);
		}
		
		// 화상 키보드용 소스 추가..
		private function onScreenKeyboard(event:FocusEvent):void {
			switch(event.type) {
				case FocusEvent.FOCUS_IN :
					if ( FlexGlobals.topLevelApplication.useScreenKeyboard && editable ) {
						FlexGlobals.topLevelApplication.screenKeyboard.inputTarget = this;
						FlexGlobals.topLevelApplication.screenKeyboard.hangleComposer.reset();
						
						if ( _isPopupMode ) {
							FlexGlobals.topLevelApplication.doScreenKeyboardOpenAtPopup()
						} else {
							FlexGlobals.topLevelApplication.doScreenKeyboardOpen();
						}
					}
					
					break;
			}
		}
		
		
		public function set isPopupMode(value:Boolean):void {
			this._isPopupMode = value;
		}
		public function get isPopupMode():Boolean {
			return this._isPopupMode;
		}
	}
}