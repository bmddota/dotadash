package  {
	
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.events.Event;
	import ValveLib.*;
	
	
	public class playerPosition extends MovieClip {
		public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		private var _heroName:String;
		private var _playerID:Number;
		private var _position:Number;
		private var _lap:Number;
		private var _maxLaps:Number;
		
		public var heroPortrait_mc:MovieClip;
		public var background_mc:MovieClip;
		public var position_txt:TextField;
		public var lap_txt:TextField;
		public var playerName_txt:TextField;
		
		public function playerPosition(newHeroName:String="", newPlayerID:Number=0, newPosition:Number=0, newLap:Number=0, newMaxLaps:Number=0) {
			heroName = newHeroName;
			playerID = newPlayerID;
			position = newPosition;
			maxLaps = newMaxLaps;
			lap = newLap;
			
			this.background_mc.gotoAndPlay(playerID+1);
		}
		
		public function set heroName(value:String):void
		{
			_heroName = value;
			Globals.instance.LoadHeroImage(value.replace('npc_dota_hero_', ''), this.heroPortrait_mc);
			trace("HERO PORTRAIT SCALES: SCALEX: "+this.heroPortrait_mc.scaleX+" SCALEY: "+this.heroPortrait_mc.scaleY+" WIDTH: "+this.heroPortrait_mc.width+" HEIGHT: "+this.heroPortrait_mc.height);
			this.heroPortrait_mc.scaleX = 64/this.heroPortrait_mc.width;
			this.heroPortrait_mc.scaleY = 36/this.heroPortrait_mc.height;
			this.dispatchEvent(new Event("heroNameSet"));
		}
		
		public function get heroName():String
		{
			return _heroName;
		}
		
		public function set playerID(value:Number):void{
			_playerID = value;
			this.playerName_txt.htmlText = Globals.instance.Players.GetPlayerName(value);
			this.dispatchEvent(new Event("playerIDSet"));
		}
		
		public function get playerID():Number{
			return _playerID;
		}
		
		public function set lap(value:Number):void{
			_lap = value; 
			this.lap_txt.text = Globals.instance.GameInterface.Translate("#DD_lap")+": "+value+"/"+this.maxLaps;
			this.dispatchEvent(new Event("lapSet"));
		}
		
		public function get lap():Number{
			return _lap;
		}
		
		public function get maxLaps():Number{
			return _maxLaps;
		}
		
		public function set maxLaps(value:Number):void{
			_maxLaps = value;
			this.dispatchEvent(new Event("maxLapSet"));
		}
		
		public function set position(value:Number):void{
			if(_position != value)
			{
				this.y = 52*value;
				this.position_txt.text = String(value);
			}
			_position = value; 
			this.dispatchEvent(new Event("positionSet"));
		}
		
		public function get position():Number{
			return _position;
		}
		
	}
	
}
