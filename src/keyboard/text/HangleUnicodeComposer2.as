package keyboard.text {
	public class HangleUnicodeComposer2 {
		public var restrict:Number = 3000;	// 글자제한
		private var instant:Array = new Array();
		private var initialJamo:Array = new Array(0x3131,0x3132,0x3134,0x3137,0x3138,0x3139,0x3141,0x3142,0x3143,0x3145,0x3146,0x3147,0x3148,0x3149,0x314A,0x314B,0x314C,0x314D,0x314E);
		private var medialJamo:Array = new Array(0x314F,0x3150,0x3151,0x3152,0x3153,0x3154,0x3155,0x3156,0x3157,0x3158,0x3159,0x315A,0x315B,0x315C,0x315D,0x315E,0x315F,0x3160,0x3161,0x3162,0x3163);
		private var finalJamo:Array = new Array("",0x3131,0x3132,0x3133,0x3134,0x3135,0x3136,0x3137,0x3139,0x313A,0x313B,0x313C,0x313D,0x313E,0x313F,0x3140,0x3141,0x3142,0x3144,0x3145,0x3146,0x3147,0x3148,0x314A,0x314B,0x314C,0x314D,0x314E);
		public var compositionString:String = "";	// 조합이 완료된 문자
		public var extra:String = "";				// 조합이 완료되지 않은 문자
		
		
		// 생성자
		public function HangleUnicodeComposer2() {}
		
		// 대기 자모 배열
		public function get instantChars():Array {
			return instant;
		}
		
		// 대기 자모 배열 지정
		public function set instantChars(value:Array):void {
			instant = [];
			instant = instant.concat(value);
		}
		
		// 한글 자모를 입력한다. ex) ㄱ, ㄴ, ㅏ, ㅣ ..
		public function addJamo(char:String):void {
			if (!compatibleHangleJamo(char)) return;
			
			instant.push(char);
			instantUpdate();
		}
		
		// 입력된 문자의 조합을 수행
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
					} else { //초성일 경우
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
							trace("TT");
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
			}
			
			trace(compositionString + " <instant : " + instant.join(",") + ">");
		}
		
		
		
		// at 위치 다음에 특수분자 넣기
		public function addSpacialChar(char:String):void{
			var at:Number = -1
			if (compositionString.length + extra.length + 1 > restrict) {
				return;
			}
			
			compositionString += extra;
	
			if (at == -1) at = compositionString.length;
			
			var strA:String = compositionString.slice(0,at);
			var strB:String = compositionString.slice(at, compositionString.length);
			
			compositionString = strA + char + strB;
			extra = "";
			instant = [];
		}
		
		// 유니코드를 입력한다.
		public function addUnicode(code:Number):void {
			addJamo(String.fromCharCode(code));
		}
		
		
		// at 위치에서 앞 글자 지우기
		public function backSpace(at:Number = -1):void {
			if (instant.length > 0) {
				instant.pop();
			} else {
				compositionString += extra;
				if (at == undefined) at = compositionString.length;
				compositionString = compositionString.slice(0,at - 1) + compositionString.slice(at + 1, compositionString.length);
				extra = "";
				instant = [];
			}
			
			instantUpdate();
		}
		
		// 2개 자모를 비교하여 결합할 수 있는 부분은 하나로 결합하여 배열로 리턴시킨다.
		public function compare2Jamo(charA:String, charB:String):Array {
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
		 * */
		public function compare3Syllables(init:String, mid:String, fin:String):Array {
			var re:Array = [];
			if (isInitialJamo(init) && isMedialJamo(mid) && isFinalJamo(fin)){
				re.push(combine3Syllables(init, mid, fin));
			} else if(isInitialJamo(init) && isMedialJamo(mid) && !isFinalJamo(fin)) {
				re.push(combine3Syllables(init, mid, ""));
				re.push(fin);
			} else {
				re = [init,mid,fin];
			}
			
			return re;
		}
		
		// 한글 자모인지 판단
		public function compatibleHangleJamo(char:String):Boolean {
			if (char.length == 0 || char.length > 1) throw Error("1개의 글자가 필요합니다.");
			var value:Boolean = false;
			
			if (char.charCodeAt(0) >= trans16to10(0x3131) && char.charCodeAt(0) <= trans16to10(0x3163)) {
				value = true; 
			}
			
			return value;
		}
		
		// 한글 자음인지 판단
		public function compatibleJaeum(char:String):Boolean {
			return (char.charCodeAt(0) > trans16to10(0x3130) && char.charCodeAt(0) < trans16to10(0x314F));
		}
		
		// 한글 모음인지 판단.
		public function compatibleMoeum(char:String):Boolean{
			return (char.charCodeAt(0) > trans16to10(0x314E) && char.charCodeAt(0) < trans16to10(0x3164));
		}
		
		// at 위치에서 뒤 글자 지우기
		public function del(at:Number):void {
			compositionString += extra;
			var str:String = compositionString;
			
			if (at == undefined) at = compositionString.length;
			
			compositionString = str.slice(0,at) + str.slice(at +2, str.length);
			extra = "";
			instant = [];
		}
		
		// 모든 데이터를 지우기
		public function reset():void {
			compositionString = "";
			extra = "";
			instant = [];
		}
		
		// 종성인지 비교한다.
		public function isFinalJamo(char:String):Boolean {
			var code:Number = char.charCodeAt(0);
			var n:Number = getIndex(finalJamo, code);
			
			if (n >= 0) {
				return true;
			} else {
				return false;
			}
		}
		
		// 초성인지 비교한다.
		public function isInitialJamo(char:String):Boolean {
			return (getIndex(initialJamo, char.charCodeAt(0)) >= 0);
		}
		
		// 중성인지 비교한다.
		public function isMedialJamo(char:String):Boolean {
			return (getIndex(medialJamo, char.charCodeAt(0)) >= 0);
		}
		
		// at 위치 다음에  공백 넣기
		public function space(at:Number):void {
			if (compositionString.length + extra.length + 1 > restrict) {
				return;
			}
			
			compositionString += extra;
	
			if (at == undefined) at = compositionString.length;
			
			var strA:String = compositionString.slice(0,at);
			var strB:String = compositionString.slice(at, compositionString.length);
			
			compositionString = strA + " " + strB;
			extra = "";
			instant = [];
		}
		
		// 초,중,종성 조합
		private function combine3Syllables(init:String, mid:String, fin:String):String {
			var initCode:Number = getIndex(initialJamo, init.charCodeAt(0));
			var midCode:Number = getIndex(medialJamo, mid.charCodeAt(0));
			var finCode:Number = (fin == "")? 0 : getIndex(finalJamo, fin.charCodeAt(0));
			
			return String.fromCharCode( ( (initCode * 588) + (midCode*28) + finCode ) + 44032 );
		}
		
		// 두 자모의 결합형태를 리턴시킨다. 결합이 안될 경우 ""
		private function combine(charA:String, charB:String):String {
			var re:String = "";
			var compCode:Number = 0;
			var charCodeA:Number = charA.charCodeAt(0);
			var charCodeB:Number = charB.charCodeAt(0);
			
			if (compatibleJaeum(charA) && compatibleJaeum(charB)) {
				//trace(charA + " " + charB +"둘다자음");
				switch (charCodeA) {
					case 0x3131 :
						if(charCodeB == 0x3145) compCode = 0x3133;
						
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
				//trace(charA + " " + charB +"둘다모음");
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
			} else if(isInitialJamo(charA) && isMedialJamo(charB)) {
				//trace(charA + " " + charB +"초성 + 중성");
				re = combine3Syllables(charA,charB,"");
			}
			
			if (compCode != 0) {
				return String.fromCharCode(compCode);
			}
			
			return re;
		}
	
		private function isCombinableFinalJamo(char:String):Boolean {
			var re:Boolean = false;
			switch (char.charCodeAt(0)) {
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
		
		private function getIndex(ary:Array, code:Number):Number {
			var i:Number;
			var a:Number = -1;
			
			for (i=0; i<ary.length; i++) {
				if (String(ary[i]).charCodeAt(0) == code) {
					a = i;
					
					break;
				}
			}
			
			return a;
			
		}		
	}
}