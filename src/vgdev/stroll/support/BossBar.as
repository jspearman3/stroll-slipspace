package vgdev.stroll.support 
{
	import flash.display.MovieClip;
	import vgdev.stroll.ContainerGame;
	import vgdev.stroll.props.enemies.ABST_Enemy;
	import vgdev.stroll.System;
	
	/**
	 * Helper for the boss HP bar
	 * @author Alexander Huynh
	 */
	public class BossBar 
	{
		private var mc:MovieClip;
		
		private var cg:ContainerGame;
		private var boss:ABST_Enemy;
		private var bossCheck:Boolean = false;
		
		private const BAR_WIDTH:Number = 310;
		
		private var percent:Number = 1;
		private var tgtPercent:Number = 1;
		private const DELTA_DELAY:Number = .01;
		
		private var isActive:Boolean = false;
		private var finishTimer:int = -1;
		
		public function BossBar(_cg:ContainerGame, _mc:MovieClip)
		{
			cg = _cg;
			mc = _mc;
		}
		
		public function startFight(_boss:ABST_Enemy = null):void
		{
			bossCheck = _boss != null;
			boss = _boss;
			
			cg.gui.mc_progress.visible = false;
			mc.gotoAndPlay("in");
			mc.base.mc_bar.width = 0;
			mc.base.tf_percent.text = "0%";
			
			percent = 1;
			tgtPercent = 0;
			isActive = true;
		}
		
		public function setPercent(perc:Number):void
		{
			percent = perc;
		}
		
		public function step():void
		{
			if (!isActive) return;
			
			if (boss != null)
				percent = boss.getHP() / boss.getHPmax();
			else if (bossCheck)
			{
				bossCheck = false;
				percent = 0;
			}
			
			if (finishTimer > 0)
			{
				finishTimer--;
				if (finishTimer == 15)
					mc.gotoAndPlay("out");
				else if (finishTimer == 0)
				{
					cg.gui.mc_progress.visible = true;
					isActive = false;
					finishTimer = -1;
					return;
				}
			}
			
			if (tgtPercent > percent)
				tgtPercent = System.changeWithLimit(tgtPercent, -DELTA_DELAY, percent, 1);
			else if (tgtPercent < percent)
				tgtPercent = System.changeWithLimit(tgtPercent, DELTA_DELAY, 0, percent);
			else
				return;
				
			mc.base.mc_bar.width = tgtPercent * BAR_WIDTH;
			mc.base.tf_percent.text = int(100 * tgtPercent) + "%";
			
			if (finishTimer == -1 && percent == 0)
				finishTimer = 90;
		}
	}
}