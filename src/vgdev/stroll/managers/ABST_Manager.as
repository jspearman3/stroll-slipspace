package vgdev.stroll.managers 
{
	import vgdev.stroll.ContainerGame;
	import vgdev.stroll.props.ABST_Object;
	import vgdev.stroll.System;

	/**
	 * Abstract Manager class, for managing mulitple instances of related objects
	 * @author Alexander Huynh
	 */
	public class ABST_Manager 
	{
		protected var cg:ContainerGame;
		
		/// An array of ABST_Objects
		protected var objArray:Array;
		
		public function ABST_Manager(_cg:ContainerGame) 
		{
			cg = _cg;
			objArray = [];
		}
		
		/**
		 * Called once per frame by ContainerGame
		 */
		public function step():void
		{
			// -- override this function
			for (var i:int = objArray.length - 1; i >= 0; i--)
				if (objArray[i].step())
					objArray.splice(i, 1);
		}
		
		/**
		 * Set this Manager's objArray to the one given
		 * @param	objs		an Array of ABST_Objects
		 */
		public function setObjects(objs:Array):void
		{
			for (var i:int = objArray.length - 1; i >= 0; i--)
				objArray[i].kill();
			objArray = objs;
		}
		
		/**
		 * Add an ABST_Object to this manager
		 * @param	obj			an ABST_Object to be managed
		 */
		public function addObject(obj:ABST_Object):void
		{
			objArray.push(obj);
		}
		
		/**
		 * Get the number of objects managed by this manager
		 * @return				How many objects are in this manager
		 */
		public function numObjects():int
		{
			return objArray.length;
		}
		
		/**
		 * Given an object, determines if it has collided with another object in this manager.
		 * @param	o			The object to check for
		 * @param	precise		Whether to use distance checking (false), or pixel-perfect checking (true)
		 * @return				The first ABST_Object that o is colliding with, else null
		 */
		public function collideWithOther(o:ABST_Object, precise:Boolean = false):ABST_Object
		{
			if (!o.isActive())
				return null;
			var other:ABST_Object;
			for (var i:int = 0; i < objArray.length; i++)
			{
				other = objArray[i];
				if (!other.isActive() || collisionException(o, other))
					continue;
				if (System.getDistance(o.mc_object.x, o.mc_object.y, other.mc_object.x, other.mc_object.y) < Math.max(o.mc_object.width, other.mc_object.width))
				{
					if (!precise || other.mc_object.hitTestPoint(o.mc_object.x + System.GAME_OFFSX, o.mc_object.y + System.GAME_OFFSY, true))
						return other;
				}
			}
			return null;
		}
		
		/**
		 * Defines when to ignore collisions between a and b
		 * @param	a	ABST_Object
		 * @param	b	ABST_Object
		 * @return		true to ignore collision between a and b
		 */
		protected function collisionException(a:ABST_Object, b:ABST_Object):Boolean
		{
			// -- override this function
			return false;
		}
		
		/**
		 * Checks if the given object is within distance to any other one in this manager
		 * @param	o			the origin ABST_Object
		 * @param	distance	the min distance, a Number
		 * @return				true if at least 1 object is within range
		 */
		public function isNearOther(o:ABST_Object, distance:Number):Boolean
		{
			var other:ABST_Object;
			for (var i:int = 0; i < objArray.length; i++)
			{
				other = objArray[i];
				if (!other.isActive())
					continue;
				var dist:Number = System.getDistance(o.mc_object.x, o.mc_object.y, other.mc_object.x, other.mc_object.y);
				if (dist != 0 && dist < distance)
					return true;
			}
			return false;
		}
		
		/**
		 * Silently all objects managed by this manager
		 */
		public function killAll():void
		{
			for (var i:int = objArray.length - 1; i >= 0; i--)
				objArray[i].destroySilently();
			objArray = [];
		}
		
		/**
		 * Clean-up function
		 */
		public function destroy():void
		{
			// -- override this function
			killAll();
			objArray = null;
			cg = null;
		}
	}
}