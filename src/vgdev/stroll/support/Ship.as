package vgdev.stroll.support 
{
	import flash.geom.ColorTransform;
	import vgdev.stroll.ContainerGame;
	import flash.display.MovieClip;
	import vgdev.stroll.System;
	
	/**
	 * Support functionality related to the ship
	 * @author Alexander Huynh, Jimmy Spearman
	 */
	public class Ship extends ABST_Support
	{		
		private var hpMax:Number = 1000;			// maximum hull strength
		private var hp:Number = hpMax;				// current hull strength
		private const MIN_HP:Number = hpMax * .2;	// amount of hull to restore to on a jump, if below that amount
		private var hullBlink:int = -1;				// helper for flashing low HP
		
		// -- Shield --------------------------------------------------------------------------------------
		private var shieldsEnabled:Boolean = true;	// if false, shields don't recharge
		
		public var mc_shield:MovieClip;				// reference to the shield MovieClip
		private var shieldMax:Number = 100;			// actual value of shields
		private var shield:Number = shieldMax;		// max value of shields
		
		public var shieldReCurr:int = 0;			// current reboot timer
		public var shieldRecharge:int = 90;			// time since last hit until shield starts to recharge
		private var shieldReAmt:Number = .25;		// amount to recharge shield per frame
		
		private const SHIELD_DA:Number = .03;		// amount to fade shield alpha per frame
		private var shieldCD:int = 0;				// current frames to hold before starting shield fade
		private const SHIELD_CD:int = 15;			// frames to hold before starting shield fade
		private const SHIELD_MA:Number = .1;		// minimum alpha of shield as long as it is non-zero
		
		private var shieldGrace:int = 0;			// period of time to make shields invulnerable, after recharging them
		private var SHIELD_GRACE:int = 45;
		
		/// Amount to multiply damage by if attack color matches shield color
		private var shieldMitigation:Number = .35;
		
		private var shieldCol:uint = System.COL_WHITE;	// current shield color
		private var shieldCTF:ColorTransform;
		// ------------------------------------------------------------------------------------------------
		
		// -- Navigation ----------------------------------------------------------------------------------
		public var shipHeading:Number = 0;				//Number determining how far off course ship is. Maintain this at 0 for best navigation.
		public var navOnline:Boolean = true; 			// boolean determining if slipdrive can function
		
		public const SHIP_HEADING_MAX:Number = 1; 		//Max value shipHeading can have
		public const SHIP_HEADING_MIN:Number = -1; 		//Min value shipHeading can have
		
		private const HEADING_RUNAWAY:Number = 1.003;  	//Scaling factor applied to heading every game tick
		private const HEADING_JUMP:Number = 0.001;		//max value of random jumps applied to the heading every game tick 
		private const DAMAGE_JUMP_FACTOR:Number = 0.01;	//max value of random jumps applied to the heading every game tick 
		// ------------------------------------------------------------------------------------------------
		
		// -- Slipdrive -----------------------------------------------------------------------------------
		public var slipRange:Number = 0;				// 'distance' until slipdrive is in range
		private var MAX_SLIP_SPEED:Number = .03;
		private var MIN_SLIP_SPEED:Number = .01;
		
		public var slipSpeed:Number = MAX_SLIP_SPEED;	// amount to reduce slipRange per frame
		public var jammable:int = 0;					// if non-zero, prevents jumping if at least jammable enemies are present
		
		private var bossOverride:Boolean = false;		// if true, override normal vars; something special is happening
		// ------------------------------------------------------------------------------------------------
		
		private const BAR_BIG_WIDTH:Number = 157.7;		// SP/HP bar
		private var hpCTF:ColorTransform;
		
		public function Ship(_cg:ContainerGame)
		{
			super(_cg);
			mc_shield = cg.game.mc_ship.shield;
			
			shieldCTF = new ColorTransform();
			setShieldColor(shieldCol);
			
			hpCTF = new ColorTransform();
			cg.gui.bar_hp.transform.colorTransform = hpCTF;
			updateIntegrity();
		}
		
		/**
		 * Return current ship's current shield value
		 * @return		ship.shield
		 */
		public function getShields():Number
		{
			return shield;
		}
		
		/**
		 * Return current ship's current shield value as a % of max
		 * @return		ship.shield / ship.shieldMax
		 */
		public function getShieldPercent():Number
		{
			return shield / shieldMax;
		}
		
		/**
		 * Return current ship's current hull points
		 * @return		ship.hp
		 */
		public function getHP():Number
		{
			return hp;
		}
		
		/**
		 * Return current ship's current hull points as a % of max
		 * @return		ship.hp / ship.hpMax
		 */
		public function getHPPercent():Number
		{
			return hp / hpMax;
		}
		
		/**
		 * Restore the ship's HP to the minumum amount, if below that amount
		 */
		public function minRestore(savedHP:Number = 0):void
		{
			savedHP = Math.max(savedHP, MIN_HP);
			hp = Math.max(hp, savedHP);
			updateIntegrity();
		}
		
		/**
		 * Deal damage to the ship (with shields in effect)
		 * @param	dmg				Amount of damage to deal (a positive value to damage)
		 * @param	col				Color type of damage
		 * @param	mitigation		If provided, use this instead of default mitigation
		 * @param	noShake			If true, don't shake cam
		 */
		public function damage(dmg:Number, col:uint = 0, mitigation:Number = -1, noShake:Boolean = false):void
		{
			if (mitigation == -1)
				mitigation = shieldMitigation;
				
			// pretend colored attacks don't exist if shield freq hasn't been unlocked yet
			if (cg.level.sectorIndex <= 4)
				col = 0;
			
			// shields absorb all damage until it breaks
			// a 10 damage attack against 100 hull and 20 shield results in 100 hull and 10 shield
			// a 10 damage attack against 100 hull and 1 shield results in 100 hull and 0 shield
			// a 10 damage attack against 100 hull and 0 shield results in 90 hull and 0 shield
			if (shield > 0)
			{
				if (shieldCol == col)
					dmg *= mitigation;
				if (shieldGrace == 0)
					shield = System.changeWithLimit(shield, -dmg, 0);
				SoundManager.playSFX("sfx_hitshield1");
			}
			else
			{
				hp = System.changeWithLimit(hp, -dmg, 0);
				adjustHeading((Math.random() - 0.5) * dmg * DAMAGE_JUMP_FACTOR);
				if (!noShake)
				{
					cg.camera.setShake(10);	// TODO set shake duration based on damage taken
					SoundManager.playSFX("sfx_hithull1");
				}
			}
						
			updateIntegrity();
			
			if (hp == 0)
			{
				destroyShip();
				return;
			}
			else if (hp <= 300 && hullBlink == -1)
				hullBlink = 30;
			
			if (shield > 0)
				mc_shield.base.alpha = .75;
			else if (mc_shield.base.alpha != 0)
			{
				mc_shield.fx.gotoAndPlay("offline");
				mc_shield.base.alpha = 0;
			}
			
			cg.setHitMask(shield == 0);
				
			shieldCD = SHIELD_CD;
			shieldReCurr = shieldRecharge;
		}
		
		/**
		 * Deal direct damage to the hull, ignoring shields
		 * @param	dmg
		 * @param	noShake			If true, don't shake cam
		 */
		public function damageDirect(dmg:Number, noShake:Boolean = false):void
		{
			hp = System.changeWithLimit(hp, -dmg, 0);
			adjustHeading((Math.random() - 0.5) * dmg * DAMAGE_JUMP_FACTOR);
			updateIntegrity();
			if (!noShake)
			{
				cg.camera.setShake(10);	// TODO set shake duration based on damage taken
				SoundManager.playSFX("sfx_hithull1");
			}
			
			if (hp <= 300 && hullBlink == -1)
				hullBlink = 30;
			
			if (hp == 0)
				destroyShip();
		}
		
		/**
		 * Update the UI
		 */
		private function updateIntegrity():void
		{
			var hpPerc:Number = hp / hpMax;
			var spPerc:Number = shield / shieldMax;
			
			// textfields
			cg.gui.tf_hull.text = Math.ceil(100 * hpPerc).toString();
			cg.gui.tf_shield.text = Math.ceil(100 * spPerc).toString();
			
			// bars
			cg.gui.bar_hp.width = hpPerc * BAR_BIG_WIDTH;
			cg.gui.bar_sp.width = spPerc * BAR_BIG_WIDTH;
			
			// colors
			/*if (hpPerc < .3)
				hpCTF.color = System.COL_RED;
			else if (hpPerc < .6)
				hpCTF.color = System.COL_YELLOW;
			else
				hpCTF.color = System.COL_GREEN;*/
			//cg.gui.bar_hp.transform.colorTransform = hpCTF;
		}
		
		/**
		 * Set the color of the ship's shield
		 * @param	col		The color to use
		 */
		public function setShieldColor(col:uint):void
		{
			shieldCol = col;
			if (col == System.COL_WHITE)
				shieldCTF = new ColorTransform();
			else
				shieldCTF.color = shieldCol;
			mc_shield.transform.colorTransform = shieldCTF;
			cg.gui.bar_sp.transform.colorTransform = shieldCTF;
			cg.gui.bar_hp.transform.colorTransform = shieldCTF;
			
			if (shield > 0)
			{
				mc_shield.fx.gotoAndPlay("rebootStart");
				mc_shield.base.alpha = Math.max(mc_shield.base.alpha, .5);
				shieldCD = SHIELD_CD;
			}
		}
		
		/**
		 * Change the heading of the ship
		 * @param	change		Number, the amount to change by (should be constrained by SHIP_HEADING_MIN, SHIP_HEADING_MAX)
		 */
		public function adjustHeading(change:Number):void 
		{
			var newHeading:Number = shipHeading + change;
			
			if (newHeading > SHIP_HEADING_MAX) {
				shipHeading = SHIP_HEADING_MAX;
			} else if (newHeading < SHIP_HEADING_MIN) {
				shipHeading = SHIP_HEADING_MIN;
			} else {
				shipHeading = newHeading;
			}
		}
		
		/**
		 * ...
		 * @param	factor		...
		 */
		public function scaleHeading(factor:Number):void
		{
			var change:Number = shipHeading * factor - shipHeading;
			adjustHeading(change);
		}
		
		public function setShieldsEnabled(enabled:Boolean):void
		{
			shieldsEnabled = enabled;
			if (!shieldsEnabled)
			{
				shieldCD = SHIELD_CD;
				shieldReCurr = shieldRecharge;
				if (shield != 0)
				{
					shield = 0;
					cg.setHitMask(shield == 0);
					
					mc_shield.fx.gotoAndPlay("offline");
					mc_shield.base.alpha = 0;
				}
			}
			updateIntegrity();
		}
		
		/**
		 * Helper to update shield cooldowns and graphics
		 */
		private function updateShields():void
		{
			if (!shieldsEnabled) return;
			
			if (shieldGrace > 0)
				shieldGrace--;
			
			if (shieldReCurr > 0)
			{
				if (--shieldReCurr == 0)
				{
					cg.setHitMask(false);
					mc_shield.fx.gotoAndPlay("rebootStart");
					SoundManager.playSFX("sfx_shieldrecharge");
				}
			}
			else if (shield < shieldMax)
			{
				shield = System.changeWithLimit(shield, shieldReAmt, 0, shieldMax);
				if (shield == shieldMax)
				{
					mc_shield.fx.gotoAndPlay("rebootFull");
					mc_shield.base.alpha = SHIELD_MA;
				}
				updateIntegrity();
			}
			
			if (shieldCD > 0)
			{
				shieldCD--;
			}
			else if (mc_shield.base.alpha > SHIELD_MA)
			{
				mc_shield.base.alpha = System.changeWithLimit(mc_shield.base.alpha, -SHIELD_DA, SHIELD_MA);
			}
		}
		
		/**
		 * Reboot a % of the ship's shields
		 * @param	amt		% of shields to reboot
		 */
		public function rebootShield(amt:Number):void
		{
			if (shield == shieldMax) return;
			shield = System.changeWithLimit(shield, amt * shieldMax, 0, shieldMax);
			
			if (shieldReCurr != 0)					// recharge counter is reset unless it's already running
				shieldReCurr = shieldRecharge;
			
			cg.setHitMask(false);
			mc_shield.fx.gotoAndPlay("rebootStart");
			SoundManager.playSFX("sfx_shieldrecharge");
			
			updateIntegrity();
			shieldGrace = SHIELD_GRACE;
		}
		
		/**
		 * Gradually drift the ship's heading away from the center
		 */
		private function updateNavigation():void {
			if (cg.atHomeworld() || bossOverride)		// quit if at a homeworld or in a special sector
				return;
			
			scaleHeading(HEADING_RUNAWAY);
			adjustHeading((Math.random() - 0.5) * HEADING_JUMP);
			slipSpeed = MAX_SLIP_SPEED - ((MAX_SLIP_SPEED - MIN_SLIP_SPEED) * Math.abs(shipHeading));
			//trace("Current Heading: " + shipHeading + "Current Slip Speed: " + slipSpeed);
		}
		
		/**
		 * Advance the ship's progress and update relevant UI
		 */
		private function updateSlip():void
		{
			if (bossOverride || hp == 0) return;
			if (slipRange > 0)
			{
				slipRange = System.changeWithLimit(slipRange, -slipSpeed, 0);
				if (slipRange == 0)
				{
					SoundManager.playSFX("sfx_readybeep1B", .7);
					cg.gui.tf_distance.text = "In range";
					cg.gui.large_indicator.gotoAndStop("green");
				}
				else
					cg.gui.tf_distance.text = Math.ceil(slipRange).toString() + " LY";
			}
		}
		
		/**
		 * Halt progress in special scenarios
		 * @param	isOverride		true to override slipdrive progress
		 */
		public function setBossOverride(isOverride:Boolean):void
		{
			bossOverride = isOverride;
			if (bossOverride)
				cg.gui.tf_distance.text = "ERROR";
		}
		
		/**
		 * Check if the slipdrive is ready
		 * @return		"ready" if jump is ready; otherwise reason why not
		 */
		public function isJumpReady():String
		{
			// TODO add other limiting conditions here
			if (isJumpReadySpecific("repair")) {
				return "repair";
			}
			if (isJumpReadySpecific("jammed")) {
				return "jammed";
			}
			if (isJumpReadySpecific("heading")) {
				return "heading";
			}
			return isJumpReadySpecific("range") ? "range" : "ready";
		}
		
		/**
		 * Checks if the ship can jump given a specific reason
		 * @param	str		the reason
		 * @return			true if jump isn't ready (opposite of what you think!)
		 */
		public function isJumpReadySpecific(str:String):Boolean
		{
			switch (str)
			{
				case "repair":
					return !navOnline;
				break;
				case "jammed":
					return jammable != 0 && cg.managerMap[System.M_ENEMY].numObjects() >= jammable;
				break;
				case "heading":
					return !isHeadingGood();
				break;
				case "range":
					return slipRange != 0;
				break;
				default:
					return false;
			}
		}
		
		/**
		 * Returns if the ship's heading is close enough to the center to jump
		 * @return		true if the ship can jump
		 */
		public function isHeadingGood():Boolean 
		{
			return (Math.abs(shipHeading) < 0.035);
		}
		
		/**
		 * Attempt to jump the ship to the next sector
		 * @return		true if the jump succeeded
		 */
		public function jump():Boolean
		{
			if (isJumpReady())
			{
				cg.jump();
				cg.gui.large_indicator.gotoAndStop(1);
				return true;
			}
			return false;
		}
		
		override public function step():void
		{
			updateSlip();
			updateNavigation();
			updateShields();
			
			// low HP blink
			if (hullBlink != -1)
			{
				if (--hullBlink < 0)
					hullBlink = 100 * (hp / hpMax) + 3;
				cg.gui.tf_hull.visible = hullBlink > 2;
			}
		}
		
		private function destroyShip():void
		{
			hullBlink = -1;
			cg.gui.tf_hull.visible = true;
			cg.killShip();
		}
		
		override public function destroy():void 
		{
			mc_shield = null;
			super.destroy();
		}
	}
}