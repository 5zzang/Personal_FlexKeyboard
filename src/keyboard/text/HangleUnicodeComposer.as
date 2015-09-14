package keyboard.text {
	import flash.events.EventDispatcher;
	import keyboard.events.HangleTextEvent;
	
	// 조합된 글자가 변경되었을 경우 발생한다. 이 이벤트를 받아서 텍스트 필드를 업데이트 하면 된다.
	[Event(name = "update", type = "keyboard.events.HangleTextEvent")]
	// 제한된 글자수를 넘어서려고 할 때 발생한다.
	[Event(name = "limited", type = "keyboard.events.HangleTextEvent")]
	[Event(name = "error", type = "keyboard.events.HangleTextEvent")]
	
	
	
	// 한글 자모를 조합하여 문자를 만드는 클래스임.
	public class HangleUnicodeComposer extends EventDispatcher {
		// 초성에 해당하는 자음 영역
		private const INITIAL:Array = new Array(0x3131,0x3132,0x3134,0x3137,0x3138,0x3139,0x3141,0x3142,0x3143,0x3145,0x3146,0x3147,0x3148,0x3149,0x314A,0x314B,0x314C,0x314D,0x314E);
		// 중성에 해당하는 모음 영역
		private const MEDIAL:Array = new Array(0x314F,0x3150,0x3151,0x3152,0x3153,0x3154,0x3155,0x3156,0x3157,0x3158,0x3159,0x315A,0x315B,0x315C,0x315D,0x315E,0x315F,0x3160,0x3161,0x3162,0x3163);
		// 종성에 해당하는 자음 영역
		private const FINAL:Array = new Array("",0x3131,0x3132,0x3133,0x3134,0x3135,0x3136,0x3137,0x3139,0x313A,0x313B,0x313C,0x313D,0x313E,0x313F,0x3140,0x3141,0x3142,0x3144,0x3145,0x3146,0x3147,0x3148,0x314A,0x314B,0x314C,0x314D,0x314E);
		private var instant:Array = new Array();
		private static var used:Boolean = false;
		
		
		// HangleUnicodeComposer 생성자
		public function HangleUnicodeComposer() {
			if (used) return;
			used = true;
		}
		
		// 초,중,종성에 해당하는 자모를 조합한다.
		static public function getString3Syllables(init:String, mid:String, fin:String):String{
			var uni:HangleUnicodeComposer = new HangleUnicodeComposer();
			return uni.combine3Syllables(init,mid,fin);
		}
		
		// 한글자음인지 판단한다.(현실적인 자음의 범위 3131 ~ 314E)
		static public function isHangleJaeum(char:String):Boolean{
			var uni:HangleUnicodeComposer = new HangleUnicodeComposer();
			return uni.compatibleJaeum(char); 
		}
		
		// 한글 자모인지 판단한다.(ref. http://www.unicode.org/charts/PDF/U3130.pdf, 현실적인 영역 0x3130 ~ 0x318F)
		static public function isHangleJamo(char:String):Boolean{
			var uni:HangleUnicodeComposer = new HangleUnicodeComposer();
			return uni.compatibleHangleJamo(char);
		}
		
		// 한글 모음인지  판단한다.(현실적인 모음의 범위 314F ~ 3163)
		static public function isHangleMoeum(char:String):Boolean{
			var uni:HangleUnicodeComposer = new HangleUnicodeComposer();
			return uni.compatibleMoeum(char); 
		}
		
		// 조합이 완료된 문자. 더이상 자모조합이 불가능한 문자이므로 Backspace 로 지우면 한 글자씩 지워진다.
		public var compositionString:String = "";
		
		// 조합이 완료되지 않은 문자. 자모조합이 가능한 문자이므로 Backspace 로 지우면 한 자모씩 지워진다.
		public var extra:String = "";
		
		// extra의 한글자모 배열(extra 의 자모배열이라고 보면 된다)
		public function get instantChars():Array {
			return instant;
		}
		
		// 대기상태의 한글자모 배열을 입력한다. extra의 자모배열을 조작하기 때문에 조심해야 한다.
		public function set instantChars(value:Array):void {
			instant = value.concat();
		}
		
		// 글자수를 제한한다. (기본 3000)
		public var restrict:uint = 3000;
		
		// 한글 자모를 조합하기 위해 입력한다.
		public function addJamo(char:String):void {
			if (!compatibleHangleJamo(char)) return;
			
			instant.push(char);
			instantUpdate();
		}
		
		//저장된 데이터들 
		private var archives:Array = [];
		
		/**
		 * 키값으로 현재 글자 데이터를 저장한다.
		 * 예를 들면, 여러개의 텍스트 필드를 전환해가며 사용할 때 상태를 저장하고 복원할 때 용이하다.
		 * @param key 현재 글자들을 저장하기 위한 키. key value used in saving current strings. 
		 * @param txt 이 값을 지정하면, 현재 값 대신에 이값을 저장한다. e
		 */
		public function archive(key:String, txt:String = null):uint {
			var match:Boolean = false;
			
			for each (var ap:ArchivePack in archives) {
				if (ap.key == key) {
					if (txt != null) {
						ap.compositionString = txt;
						ap.instant = [];
						ap.extra = "";
					} else {
						ap.compositionString = this.compositionString;
						ap.instant = this.instant;
						ap.extra = this.extra;
					}
					
					match = true;
				}
			}
			
			if (!match) {
				var newA:ArchivePack = new ArchivePack();
				newA.compositionString = this.compositionString;
				newA.instant = this.instant.concat();
				newA.extra = this.extra;
				newA.key = key;
				archives.push(newA);
			}
			
			return archives.length;
		}
		
		/**
		 * 키값에 해당하는 데이터 상태로 복원한다.
		 * 예를 들면, 여러개의 텍스트 필드를 전환해가며 사용할 때 상태를 저장하고 복원할 때 용이하다.
		 * compositionString, instant, extra 값이 복원된다.
		 * @param key archive에 사용한 키.
		 **/
		public function restore(key:String):String {
			var match:Boolean = false;
			
			for each (var ap:ArchivePack in archives) {
				if (ap.key == key) {
					this.compositionString = ap.compositionString;
					this.instant = ap.instant.concat();
					this.extra = ap.extra;
					match = true;
					
					break;
				}
			}
			
			if (!match) {
				return "";
			} else {
				return this.compositionString + this.extra;
			}
		}
		
		private function instantUpdate():void {	
			switch (instant.length) {
				case 0 :
					extra = "";
					
					break;
				case 1 :
					//모음일 경우
					if (compatibleMoeum(instant[0])) {
						compositionString += instant[0];
						instant = [];
						extra = "";
						//초성일 경우
					} else {
						extra = instant[0];
					}
					
					break;
				
				//instant[0]은 자음이고 
				//instant[1]이 그 무엇일 경우
				case 2:
					//모음이면 
					if (compatibleMoeum(instant[1])) {
						//중성이라면
						if (isMedialJamo(instant[1])) {
							extra = combine(instant[0],instant[1]);
						} else {
							compositionString += instant[0];
							extra = instant[1];
							instant.shift();
						}
					} else {	//자음이라면
						compositionString += instant[0];
						extra = instant[1];
						instant.shift();
					}
					
					break;
				
				//instant[0]은 자음이고 
				//instant[1]은 instant[0]와 결합될 수 있는 형태
				//instant[2]이 그 무엇일 경우
				case 3:
					//3번째가 모음이면
					if (compatibleMoeum(instant[2])) {
						//2번째 모음과 결합할 수 있는 형태 이라면 결합 형태의 모음으로 instant에 남김
						if (combine(instant[1], instant[2])!= "") {
							instant[1] = combine(instant[1], instant[2]);
							instant.pop();
							extra = combine3Syllables(instant[0], instant[1], "");
						} else {
							compositionString += combine(instant[0], instant[1]);
							compositionString += instant[2];
							extra = "";
							instant = [];
						}
					} else {	//3번째가 자음이면
						//종성이면
						if (isFinalJamo(instant[2])) {
							//이 후 입력에 따라 자음조합이 될 수 있거나 모음에 의해 초성이 될 수 있다면 instant에 남김
							if (isCombinableFinalJamo(instant[2]) || isInitialJamo(instant[2])) {
								extra = combine3Syllables(instant[0], instant[1], instant[2]);
							} else {
								compositionString += combine3Syllables(instant[0], instant[1], instant[2]);
								extra = "";
								instant = [];
							}
						} else {	//자음이지만 종성이 아닐 경우
							compositionString += combine(instant[0], instant[1]);
							extra = instant[2];
							instant.shift();
							instant.shift();
						}
					}
					
					break;			
				
				
				//instant[0]은 자음 
				//instant[1]은 모음
				//instant[2]는 결합할 수 있는 종성 혹은 초성, 모음
				//instant[3]이 그 무엇일 경우
				case 4 :
					//4번째가 모음이면
					if (compatibleMoeum(instant[3])) {
						//3번째가 모음이면 
						if (compatibleMoeum(instant[2])) {
							compositionString += combine(instant[0], combine(instant[1], instant[2]));
							extra = instant[3];
							instant.shift();
							instant.shift();
							instant.shift();
						} else {	//3번째가 자음이면
							//4번째가 중성이면
							if (isMedialJamo(instant[3])) {
								compositionString += combine(instant[0], instant[1]);
								extra = combine(instant[2], instant[3]);
								instant.shift();
								instant.shift();
							} else {
								compositionString += combine3Syllables(instant[0], instant[1], instant[2]);
								extra = instant[3];
								instant.shift();
								instant.shift();
								instant.shift();
							}
						}					
					} else {	//4번째가 자음이면
						//3번째가 모음이면 
						if (compatibleMoeum(instant[2])) {
							//4번째 자음이 결합할 수 있는 형태의 종성형이라면 인스턴트에 남김
							//또는 초성형이 될 수 있는 형태라면 인스턴트에 남김
							if (isCombinableFinalJamo(instant[3]) || isInitialJamo(instant[3])) {
								extra = combine3Syllables(instant[0], combine(instant[1], instant[2]), instant[3]);
							} else {
								compositionString += combine3Syllables(instant[0], combine(instant[1], instant[2]), instant[3]);
								extra = "";
								instant = [];
							}
						} else {	//3번째가 자음이면
							//3번째, 4번째와 결합할 수 있는 자음이면
							if (combine(instant[2],instant[3]) != "" ) {
								//초성이 될 수 있는 경우라면 instant에 남겨둔다 **
								if (isInitialJamo(instant[3])) {
									extra = combine3Syllables(instant[0], instant[1], combine(instant[2],instant[3]));
								} else {
									compositionString += combine3Syllables(instant[0], instant[1], combine(instant[2],instant[3]));
									extra = "";
									instant = [];
								}
							} else {	//3번쨰와 결합할 수 없는 자음이면
								compositionString += combine3Syllables(instant[0], instant[1], instant[2]);
								extra = instant[3];
								instant.shift();
								instant.shift();
								instant.shift();
							} 
						}
					}
					
					break;
				
				//instant[0]은 자음 
				//instant[1]은 모음
				//instant[2]는 결합할 수 있는 종성 이나 모음
				//instant[3]은 instant[2]와 결합할 수 있는 자음 혹은 초성
				//instant[4]이 그 무엇일 경우
				case 5 :
					//모음일 경우
					if (compatibleMoeum(instant[4])) {
						if (combine(instant[1], instant[2]) != "") {
							compositionString += combine3Syllables(instant[0], combine(instant[1], instant[2]), "");
						} else {
							compositionString += combine3Syllables(instant[0], instant[1], instant[2]);
						}
						
						extra = combine(instant[3], instant[4]);
						instant.shift();
						instant.shift();
						instant.shift();
					} else {	//자음이거나 조합이 불가능한 모음인 경우
						//자음일 경우
						if (compatibleJaeum(instant[4])) {
							//초성이 될 수 있는 경우 인스턴트에 남겨 둠.
							if (isInitialJamo(instant[4])) {
								compositionString += extra;
								extra = instant[4];
								instant.shift();
								instant.shift();
								instant.shift();
								instant.shift();
								//combine3Syllables(instant[0], combine(instant[1],instant[2]), combine(instant[3],instant[4]));
							} else {
								compositionString += extra;
								//compositionString += combine3Syllables(instant[0], instant[1], combine(instant[2],instant[3]));
								compositionString += instant[3];
								extra = "";
								instant.shift();
								instant.shift();
								instant.shift();
								instant.shift();
								instant.shift();
							}
							
						} else {
							compositionString += combine3Syllables(instant[0], instant[1], combine(instant[2],instant[3]));
							compositionString += instant[4];
							extra = "";
							instant = [];
						}
					}
					
					break;
				
				//instant[0]은 자음 
				//instant[1]은 모음
				//instant[2]는 결합할 수 있는 모음 
				//instant[3]은 instant[2]와 결합할 수 있는 자음
				//instant[4]이 instant[3]과 결합할 수 있는 자음, 초성
				//instant[5] 그 무엇..
				case 6 :
					//5번째 음과 결합할 수 있는 형태이면
					if (combine(instant[4],instant[5]) != "" ) {
						compositionString += combine3Syllables(instant[0],combine(instant[1],instant[2]),instant[3]);
						extra = combine(instant[4], instant[5]);
						instant.shift();
						instant.shift();
						instant.shift();
						instant.shift();						
					} else {
						compositionString += combine3Syllables(instant[0],combine(instant[1],instant[2]),combine(instant[3], instant[4]));
						extra = instant[5];
						instant.shift();
						instant.shift();
						instant.shift();
						instant.shift();
						instant.shift();
					}
					
					break;
			}
			
			if (compositionString.length + extra.length > restrict) {
				backSpace();
				dispatchEvent(new HangleTextEvent(HangleTextEvent.LIMITED, compositionString + extra));
			}
			
			trace("<instant : " + instant.join(",") + ">");
			dispatchEvent(new HangleTextEvent(HangleTextEvent.UPDATE, compositionString + extra));
		}
		
		
		/**
		 * 조합할 수 없는 글자 넣기. 조합이 불가능한 문자를 입력할 때 사용하면 된다. 특히, 영어나 특수문자를 기입할 때 사용함
		 * @param at 글자를 넣을 위치. position to insert char.
		 * */
		public function addSpecialChar(char:String, at:int = -1):void {
			if (compositionString.length + extra.length + 1 > restrict) {
				dispatchEvent(new HangleTextEvent(HangleTextEvent.LIMITED, compositionString + extra));
				
				return;
			}
			
			compositionString += extra;
			
			if (at == -1) at = compositionString.length;
			
			var strA:String = compositionString.slice(0,at);
			var strB:String = compositionString.slice(at, compositionString.length);
			
			compositionString = strA + char + strB;
			extra = "";
			instant = [];
			
			dispatchEvent(new HangleTextEvent(HangleTextEvent.UPDATE, compositionString));
		}
		
		/**
		 * 유니코드로 자모를 입력한다.
		 * @param code 한글자모에 해당하는 유니코드 unicode for korean charaters 
		 */
		public function addJamoUnicode(code:uint):void {
			addJamo(String.fromCharCode(code));
		}
		
		/**
		 * 앞 글자 지우기
		 * @param at 지울 글자 위치. position to backspace.
		 */
		public function backSpace(at:int = -1):void {	
			if (instant.length > 0) {
				instant.pop();
			} else {
				compositionString += extra;
				
				if (at == -1) at = compositionString.length;
				compositionString = compositionString.slice(0,at - 1) + compositionString.slice(at + 1, compositionString.length);
				extra = "";
				instant = [];
			}
			
			instantUpdate();
		}
		
		
		/**
		 * 2개 자모를 비교하여 결합할 수 있는 부분은 하나로 결합하여 배열로 리턴시킨다.
		 * @param charA
		 * @param charB
		 * @return 가능한 조합을 마친 글자를 포함한 배열
		 * */
		public function compare2Jamo(charA:String, charB:String):Array{
			var re:Array = [];
			if (combine(charA, charB) != "") {
				re.push(combine(charA, charB));
			} else {
				re.push(charA);
				re.push(charB);
			}
			
			return re;
		}
		
		/**
		 * 3개 자모를 초성 중성 종성 으로 비교하여 결합할 수 있는 부분은 하나로 결합하여 배열로 리턴시킨다.
		 * @param init 초성이 되는 글자
		 * @param mid 중성이 되는 글자
		 * @param fin 종성이 되는 글자
		 * @return 가능한 조합을 마친 글자를 포함한 배열
		 * */
		public function compare3Syllables(init:String, mid:String, fin:String):Array{
			var re:Array = [];
			if (isInitialJamo(init) && isMedialJamo(mid) && isFinalJamo(fin)) {
				re.push(combine3Syllables(init, mid, fin));
			} else if (isInitialJamo(init) && isMedialJamo(mid) && !isFinalJamo(fin)) {
				re.push(combine3Syllables(init, mid, ""));
				re.push(fin);
			} else {
				re = [init,mid,fin];
			}
			
			return re;
		}
		
		// 한글 자모인지 판단한다.
		public function compatibleHangleJamo(char:String):Boolean {
			if (char.length == 0 || char.length > 1) throw Error("1개의 글자가 필요합니다.");
			var value:Boolean = false;
			
			if (char.charCodeAt() >= trans16to10(0x3131) && char.charCodeAt() <= trans16to10(0x3163)) {
				value = true; 
			}
			
			return value;
		}
		
		// 한글 자음인지 판단한다.
		public function compatibleJaeum(char:String):Boolean {
			return (char.charCodeAt() > trans16to10(0x3130) && char.charCodeAt() < trans16to10(0x314F));
		}
		
		// 한글 모음인지  판단한다.
		public function compatibleMoeum(char:String):Boolean {
			return (char.charCodeAt() > trans16to10(0x314E) && char.charCodeAt() < trans16to10(0x3164));
		}
		
		// at 위치에서 뒤 글자 지우기
		public function del(at:int = -1):void {
			compositionString += extra;
			var str:String = compositionString;
			
			if (at == -1) at = compositionString.length;
			
			compositionString = str.slice(0,at) + str.slice(at +2, str.length);
			extra = "";
			instant = [];
			dispatchEvent(new HangleTextEvent(HangleTextEvent.UPDATE, compositionString));
		}
		
		// 모든 데이터를 지우기, 초기화
		public function reset():void {
			compositionString = "";
			extra = "";
			instant = [];
			archives = [];
		}
		
		// 종성인지 판단한다.
		public function isFinalJamo(char:String):Boolean {
			return (FINAL.indexOf(char.charCodeAt()) >= 0);
		}
		
		// 초성인지 판단한다.
		public function isInitialJamo(char:String):Boolean {
			return (INITIAL.indexOf(char.charCodeAt()) >= 0);
		}
		
		// 중성인지 비교한다.
		public function isMedialJamo(char:String):Boolean {
			return (MEDIAL.indexOf(char.charCodeAt()) >= 0);
		}
		
		// at 위치 다음에  공백 넣기
		public function space(at:int = -1):void {
			if (compositionString.length + extra.length + 1 > restrict) {
				dispatchEvent(new HangleTextEvent(HangleTextEvent.LIMITED, compositionString + extra));
				
				return;
			}
			
			compositionString += extra;
			
			if (at == -1) at = compositionString.length;
			
			var strA:String = compositionString.slice(0,at);
			var strB:String = compositionString.slice(at, compositionString.length);
			
			compositionString = strA + " " + strB;
			extra = "";
			instant = [];
			
			dispatchEvent(new HangleTextEvent(HangleTextEvent.UPDATE, compositionString));
		}
		
		// 초,중,종성 조합
		internal function combine3Syllables(init:String, mid:String, fin:String):String {
			var initCode:int = INITIAL.indexOf(init.charCodeAt());
			var midCode:int = MEDIAL.indexOf(mid.charCodeAt());
			var finCode:int = (fin == "")? 0 : FINAL.indexOf(fin.charCodeAt());
			
			return String.fromCharCode( ( (initCode * 588) + (midCode*28) + finCode ) + 44032 );
		}
		
		// 두 자모의 결합형태를 리턴시킨다. 결합이 안될 경우 ""
		private function combine(charA:String, charB:String):String{
			var re:String = "";
			var compCode:Number = 0;
			var charCodeA:Number = charA.charCodeAt();
			var charCodeB:Number = charB.charCodeAt();
			
			if (compatibleJaeum(charA) && compatibleJaeum(charB)) {
				switch (charCodeA) {
					case 0x3131 :
						if (charCodeB == 0x3145) compCode = 0x3133;
						
						break;
					case 0x3134 :
						if (charCodeB == 0x3148) compCode = 0x3135;
						if (charCodeB == 0x314E) compCode = 0x3136;
						
						break;
					case 0x3139 :
						if (charCodeB == 0x3131) compCode = 0x313A;
						if (charCodeB == 0x3141) compCode = 0x313B;
						if (charCodeB == 0x3142) compCode = 0x313C;
						if (charCodeB == 0x3145) compCode = 0x313D;
						if (charCodeB == 0x314C) compCode = 0x313E;
						if (charCodeB == 0x314D) compCode = 0x313F;
						if (charCodeB == 0x314E) compCode = 0x3140;
						
						break;
					case 0x3142 :
						if (charCodeB == 0x3145) compCode = 0x3144;
						
						break;
				}
			} else if (compatibleMoeum(charA) && compatibleMoeum(charB)) {
				switch (charCodeA) {
					case 0x3157 :
						if (charCodeB == 0x314F) compCode = 0x3158;
						if (charCodeB == 0x3150) compCode = 0x3159;
						if (charCodeB == 0x3163) compCode = 0x315A;
						
						break;
					case 0x315C :
						if (charCodeB == 0x3153) compCode = 0x315D;
						if (charCodeB == 0x3154) compCode = 0x315E;
						if (charCodeB == 0x3163) compCode = 0x315F;
						
						break;
					case 0x3161 :
						if (charCodeB == 0x3163) compCode = 0x3162;
						
						break;
				}
			} else if (isInitialJamo(charA) && isMedialJamo(charB)) {
				re = combine3Syllables(charA,charB,"");
			}
			
			if (compCode != 0) {
				return String.fromCharCode(compCode);
			}
			
			return re;
		}
		
		private function isCombinableFinalJamo(char:String):Boolean {
			var re:Boolean = false;
			switch (char.charCodeAt()) {
				case 0x3131 :
				case 0x3134 :
				case 0x3139 :
				case 0x3142 :
					re = true;
					
					break;
			}
			
			return re;
		}
		
		private function trans16to10(value16:Number):Number {
			return Number(value16.toString(10));
		}
	}
}


internal class ArchivePack {
	public var key:String = "";
	public var compositionString:String = "";
	public var extra:String = "";
	private var _instant:Array = [];
	
	
	public function get instant():Array {
		return _instant;
	}
	
	public function set instant(value:Array):void {
		_instant = value.concat();
	}
}