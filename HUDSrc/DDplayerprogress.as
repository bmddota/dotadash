package  {
	
	import flash.display.MovieClip;
	import ValveLib.*;
	
	public class DDplayerprogress extends MovieClip {
		public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		public var playerPositions:Vector.<playerPosition> = new Vector.<playerPosition>();
		
		public function DDplayerprogress() {
			
		}
		
		public function onLoaded():void{
			
			this.gameAPI.SubscribeToGameEvent("dd_start_race", this.OnStartRace);
			this.gameAPI.SubscribeToGameEvent("dd_position_update", this.OnPositionUpdate);
			this.gameAPI.SubscribeToGameEvent("dd_lap_update", this.OnLapUpdate);
			this.visible = true;
		}
		
		public function OnStartRace(keyValues:Object):void
		{
			for(var k:Number = 0; k < this.playerPositions.length; k++)
			{
				removeChild(this.playerPositions[k]);
			}
			
			this.playerPositions = null;
			
			var newPosition:playerPosition;
			for(var i:Number = 0; i < 10; i++)
			{
				if(this.globals.Players.IsValidPlayer(i))
				{
					newPosition = new playerPosition(this.globals.Players.GetPlayerSelectedHero(i), i, i+1, 0, keyValues.maxLaps);
					this.playerPositions.push(newPosition);
					addChild(newPosition);
				}else{
					break;
				}
			}
		}
		
		public function OnPositionUpdate(keyValues:Object):void
		{
			var positions:Array = keyValues.positions.split(",");
			for (var i:Number = 0; i<positions.length; i++) {
				GetPlayerPositionById(i).position = i+1;
			}
		}
		
		public function OnLapUpdate(keyValues:Object):void
		{
			GetPlayerPositionById(keyValues.playerID).lap = keyValues.lap;
		}
		
		public function GetPlayerPositionById(playerID:Number):playerPosition
		{
			for(var i:Number = 0; i < this.playerPositions.length; i++)
			{
				if(this.playerPositions[i].playerID == playerID)
				{
					return this.playerPositions[i];
				}
			}
			return null;
		}
		
		public function onScreenSizeChanged():void{
            this.scaleX = (this.globals.resizeManager.ScreenWidth / 1920);
            this.scaleY = (this.globals.resizeManager.ScreenHeight / 1080);
            x = this.globals.resizeManager.ScreenWidth - (178*this.scaleX);
            y = 54*this.scaleY;
            trace(("fofitemdraft::onScreenSizeChanged stageWidth/Height = " + stage.stageWidth), stage.stageHeight);
            trace(("  stage.width/height = " + stage.width), stage.height);
            trace(("  rm.screenWidth/height = " + this.globals.resizeManager.ScreenWidth), this.globals.resizeManager.ScreenHeight);
        }
	}
	
}
