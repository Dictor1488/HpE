package com.dictor.hpe.battle
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.utils.Dictionary;

   import com.dictor.hpe.injector.BattleDisplayable;

   public class HpPanel extends BattleDisplayable
   {
      private var _data:Dictionary;
      private var _rows:Dictionary;
      private var _frame:int = 0;
      private var _disposed:Boolean = false;

      public var flashLogS:Function;

      public function HpPanel()
      {
         super();
         name = "hpePlayerPanel";
         _data = new Dictionary();
         _rows = new Dictionary();
         addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
      }

      private function member(target:*, name:String):*
      {
         if (!target)
            return null;
         try
         {
            return target[name];
         }
         catch (e:Error)
         {
         }
         return null;
      }

      private function resolvePlayersPanel():*
      {
         var page:* = battlePage;
         if (!page)
            return null;

         var panel:* = member(page, "playersPanel");
         if (panel)
            return panel;

         panel = member(page, "epicRandomPlayersPanel");
         if (panel)
            return panel;

         return null;
      }

      private function holder(list:*, vehicleID:int):*
      {
         if (!list)
            return null;
         try
         {
            return list.getHolderByVehicleID(vehicleID);
         }
         catch (e:Error)
         {
         }
         try
         {
            return list.getHolderByVehicleId(vehicleID);
         }
         catch (e2:Error)
         {
         }
         return null;
      }

      private function listItemFromHolder(value:*):*
      {
         if (!value)
            return null;
         try
         {
            return value.getListItem();
         }
         catch (e:Error)
         {
         }
         var item:* = member(value, "_listItem");
         if (item)
            return item;
         return member(value, "listItem");
      }

      private function getListItem(vehicleID:int):*
      {
         var panel:* = resolvePlayersPanel();
         if (!panel)
            return null;

         var value:* = holder(member(panel, "listLeft"), vehicleID);
         if (value)
            return listItemFromHolder(value);

         value = holder(member(panel, "listRight"), vehicleID);
         if (value)
            return listItemFromHolder(value);

         return null;
      }

      private function isEnemy(vehicleID:int):Boolean
      {
         var panel:* = resolvePlayersPanel();
         if (!panel)
            return false;
         return holder(member(panel, "listRight"), vehicleID) != null;
      }

      private function ensureRow(vehicleID:int, item:*):HealthRow
      {
         var row:HealthRow = _rows[vehicleID] as HealthRow;
         if (!row)
         {
            row = new HealthRow();
            row.name = "hpeHealth_" + vehicleID;
            _rows[vehicleID] = row;
         }

         if (row.parent != item && item is DisplayObjectContainer)
         {
            if (row.parent)
                row.parent.removeChild(row);
            DisplayObjectContainer(item).addChild(row);
         }
         return row;
      }

      private function positionRow(vehicleID:int, item:*, row:HealthRow, enemy:Boolean):void
      {
         if (!item || !row)
            return;

         var icon:DisplayObject = member(item, "vehicleIcon") as DisplayObject;
         var vehicleTF:DisplayObject = member(item, "vehicleTF") as DisplayObject;
         var anchor:DisplayObject = icon ? icon : vehicleTF;

         if (anchor)
         {
            if (enemy)
               row.x = anchor.x - HealthRow.TOTAL_WIDTH - 5;
            else
               row.x = anchor.x + anchor.width + 5;
            row.y = anchor.y + Math.max(-2, (anchor.height - HealthRow.TOTAL_HEIGHT) * 0.5);
         }
         else
         {
            var itemWidth:Number = 300;
            try
            {
               itemWidth = Number(item.width);
            }
            catch (e:Error)
            {
            }
            row.x = enemy ? 4 : Math.max(4, itemWidth - HealthRow.TOTAL_WIDTH - 4);
            row.y = 0;
         }

         try
         {
            row.visible = item.visible && row.visible;
         }
         catch (e2:Error)
         {
         }
      }

      private function applyVehicle(vehicleID:int):void
      {
         var data:Object = _data[vehicleID];
         if (!data)
            return;

         var item:* = getListItem(vehicleID);
         var row:HealthRow = _rows[vehicleID] as HealthRow;
         if (!item)
         {
            if (row)
               row.visible = false;
            return;
         }

         var enemy:Boolean = isEnemy(vehicleID);
         row = ensureRow(vehicleID, item);
         row.updateHealth(int(data.currentHealth), int(data.maxHealth), enemy);
         positionRow(vehicleID, item, row, enemy);
      }

      public function as_setVehicleHealth(vehicleID:int, currentHealth:int, maxHealth:int):void
      {
         if (_disposed || vehicleID <= 0)
            return;
         _data[vehicleID] = {
            currentHealth: Math.max(0, currentHealth),
            maxHealth: Math.max(0, maxHealth)
         };
         applyVehicle(vehicleID);
      }

      public function as_refreshAll():void
      {
         if (_disposed)
            return;
         for (var key:* in _data)
            applyVehicle(int(key));
      }

      public function as_clear():void
      {
         for each (var row:HealthRow in _rows)
         {
            if (row && row.parent)
               row.parent.removeChild(row);
         }
         _rows = new Dictionary();
         _data = new Dictionary();
      }

      private function onEnterFrame(event:Event):void
      {
         if (_disposed)
            return;
         if (++_frame < 3)
            return;
         _frame = 0;
         as_refreshAll();
      }

      override protected function onDispose():void
      {
         _disposed = true;
         removeEventListener(Event.ENTER_FRAME, onEnterFrame);
         as_clear();
         super.onDispose();
      }
   }
}
