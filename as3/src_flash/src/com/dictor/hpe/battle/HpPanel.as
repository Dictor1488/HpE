package com.dictor.hpe.battle
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;

   import com.dictor.hpe.injector.BattleDisplayable;

   public class HpPanel extends BattleDisplayable
   {
      private static const LT_COLOR:uint = 0x596E4B;
      private static const MT_COLOR:uint = 0x8B6526;
      private static const TD_COLOR:uint = 0x3D4658;
      private static const SPG_COLOR:uint = 0x684940;

      private static const KEY_ALT:uint = 18;
      private static const KEY_CTRL:uint = 17;
      private static const ICON_GAP:Number = 4;

      private var _data:Dictionary;
      private var _rows:Dictionary;
      private var _iconTransforms:Dictionary;
      private var _frame:int = 0;
      private var _disposed:Boolean = false;

      private var _altDown:Boolean = false;
      private var _ctrlDown:Boolean = false;
      private var _alwaysShow:Boolean = false;
      private var _toggleLatch:Boolean = false;
      private var _keyboardAttached:Boolean = false;

      public var flashLogS:Function;

      public function HpPanel()
      {
         super();
         name = "hpePlayerPanel";
         _data = new Dictionary();
         _rows = new Dictionary();
         _iconTransforms = new Dictionary(true);

         addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
         addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
         if (stage)
            attachKeyboard();
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

      private function shouldShowHealth():Boolean
      {
         return _alwaysShow || _altDown;
      }

      private function itemIsVisible(item:*):Boolean
      {
         if (!item)
            return false;
         try
         {
            return Boolean(item.visible);
         }
         catch (e:Error)
         {
         }
         return true;
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
            var bounds:Rectangle = null;
            try
            {
               if (item is DisplayObject)
                  bounds = anchor.getBounds(DisplayObject(item));
            }
            catch (boundsError:Error)
            {
               bounds = null;
            }

            if (bounds && bounds.width > 0 && bounds.height > 0)
            {
               row.x = Math.round(enemy ? bounds.x - HealthRow.TOTAL_WIDTH - ICON_GAP : bounds.right + ICON_GAP);
               row.y = Math.round(bounds.y + (bounds.height - HealthRow.TOTAL_HEIGHT) * 0.5);
            }
            else
            {
               row.x = Math.round(enemy ? anchor.x - HealthRow.TOTAL_WIDTH - ICON_GAP : anchor.x + anchor.width + ICON_GAP);
               row.y = Math.round(anchor.y + (anchor.height - HealthRow.TOTAL_HEIGHT) * 0.5);
            }
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
            row.x = Math.round(enemy ? 4 : Math.max(4, itemWidth - HealthRow.TOTAL_WIDTH - 4));
            row.y = 0;
         }

         var data:Object = _data[vehicleID];
         row.visible = itemIsVisible(item) && shouldShowHealth() && data != null && int(data.maxHealth) > 0;
      }

      private function refreshRowVisibility():void
      {
         var show:Boolean = shouldShowHealth();
         for (var key:* in _rows)
         {
            var vehicleID:int = int(key);
            var row:HealthRow = _rows[key] as HealthRow;
            if (!row)
               continue;

            var item:* = getListItem(vehicleID);
            var data:Object = _data[vehicleID];
            row.visible = show && itemIsVisible(item) && data != null && int(data.maxHealth) > 0;
         }
      }

      private function onAddedToStage(event:Event):void
      {
         attachKeyboard();
      }

      private function attachKeyboard():void
      {
         if (_keyboardAttached || !stage)
            return;

         stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
         stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
         stage.addEventListener(Event.DEACTIVATE, onStageDeactivate, false, 0, true);
         _keyboardAttached = true;
      }

      private function detachKeyboard():void
      {
         if (!_keyboardAttached || !stage)
         {
            _keyboardAttached = false;
            return;
         }

         stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
         stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
         stage.removeEventListener(Event.DEACTIVATE, onStageDeactivate);
         _keyboardAttached = false;
      }

      private function onKeyDown(event:KeyboardEvent):void
      {
         if (_disposed)
            return;

         if (event.keyCode == KEY_ALT)
            _altDown = true;
         if (event.keyCode == KEY_CTRL)
            _ctrlDown = true;

         if (event.altKey)
            _altDown = true;
         if (event.ctrlKey)
            _ctrlDown = true;

         if (_altDown && _ctrlDown)
         {
            if (!_toggleLatch)
            {
               _alwaysShow = !_alwaysShow;
               _toggleLatch = true;
            }
         }
         else
         {
            _toggleLatch = false;
         }

         refreshRowVisibility();
      }

      private function onKeyUp(event:KeyboardEvent):void
      {
         if (_disposed)
            return;

         if (event.keyCode == KEY_ALT)
            _altDown = false;
         if (event.keyCode == KEY_CTRL)
            _ctrlDown = false;

         if (!_altDown || !_ctrlDown)
            _toggleLatch = false;

         refreshRowVisibility();
      }

      private function onStageDeactivate(event:Event):void
      {
         _altDown = false;
         _ctrlDown = false;
         _toggleLatch = false;
         refreshRowVisibility();
      }

      private function cloneTransform(value:ColorTransform):ColorTransform
      {
         return new ColorTransform(
            value.redMultiplier,
            value.greenMultiplier,
            value.blueMultiplier,
            value.alphaMultiplier,
            value.redOffset,
            value.greenOffset,
            value.blueOffset,
            value.alphaOffset
         );
      }

      private function getOriginalIconTransform(icon:DisplayObject):ColorTransform
      {
         var original:ColorTransform = _iconTransforms[icon] as ColorTransform;
         if (!original)
         {
            original = cloneTransform(icon.transform.colorTransform);
            _iconTransforms[icon] = original;
         }
         return original;
      }

      private function tintFromScreenshot(original:ColorTransform, color:uint):ColorTransform
      {
         var red:Number = ((color >> 16) & 0xFF) / 128.0;
         var green:Number = ((color >> 8) & 0xFF) / 128.0;
         var blue:Number = (color & 0xFF) / 128.0;

         return new ColorTransform(
            original.redMultiplier * red,
            original.greenMultiplier * green,
            original.blueMultiplier * blue,
            original.alphaMultiplier,
            original.redOffset,
            original.greenOffset,
            original.blueOffset,
            original.alphaOffset
         );
      }

      private function applyIconColor(item:*, vehicleClass:String):void
      {
         if (!item)
            return;

         var icon:DisplayObject = member(item, "vehicleIcon") as DisplayObject;
         if (!icon)
            return;

         var original:ColorTransform = getOriginalIconTransform(icon);
         var className:String = vehicleClass ? vehicleClass.toLowerCase() : "";
         var color:uint = 0;
         var shouldTint:Boolean = true;

         switch (className)
         {
            case "lighttank":
               color = LT_COLOR;
               break;
            case "mediumtank":
               color = MT_COLOR;
               break;
            case "at-spg":
               color = TD_COLOR;
               break;
            case "spg":
               color = SPG_COLOR;
               break;
            case "heavytank":
            default:
               shouldTint = false;
               break;
         }

         try
         {
            icon.transform.colorTransform = shouldTint ? tintFromScreenshot(original, color) : cloneTransform(original);
         }
         catch (e:Error)
         {
         }
      }

      private function restoreIconColors():void
      {
         for (var key:* in _iconTransforms)
         {
            var icon:DisplayObject = key as DisplayObject;
            var transform:ColorTransform = _iconTransforms[key] as ColorTransform;
            if (icon && transform)
            {
               try
               {
                  icon.transform.colorTransform = cloneTransform(transform);
               }
               catch (e:Error)
               {
               }
            }
         }
         _iconTransforms = new Dictionary(true);
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
         applyIconColor(item, String(data.vehicleClass));
      }

      public function as_setVehicleHealth(vehicleID:int, currentHealth:int, maxHealth:int, vehicleClass:String = ""):void
      {
         if (_disposed || vehicleID <= 0)
            return;
         _data[vehicleID] = {
            currentHealth: Math.max(0, currentHealth),
            maxHealth: Math.max(0, maxHealth),
            vehicleClass: vehicleClass ? vehicleClass : ""
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
         restoreIconColors();
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
         detachKeyboard();
         removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
         removeEventListener(Event.ENTER_FRAME, onEnterFrame);
         as_clear();
         super.onDispose();
      }
   }
}
