package com.dictor.hpe.battle
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.filters.DropShadowFilter;
   import flash.text.AntiAliasType;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;

   public class HealthRow extends Sprite
   {
      public static const BAR_WIDTH:Number = 82;
      public static const BAR_HEIGHT:Number = 6;
      public static const TEXT_WIDTH:Number = 38;
      public static const TOTAL_WIDTH:Number = BAR_WIDTH + TEXT_WIDTH + 5;
      public static const TOTAL_HEIGHT:Number = 22;

      private var _bg:Shape;
      private var _fill:Shape;
      private var _text:TextField;
      private var _enemy:Boolean = false;

      public function HealthRow()
      {
         super();
         mouseEnabled = false;
         mouseChildren = false;

         _bg = new Shape();
         _fill = new Shape();
         _text = new TextField();

         _text.defaultTextFormat = new TextFormat("$UniversCondC", 14, 0xFFFFFF, false, false, false, "", "", "right");
         _text.embedFonts = true;
         _text.antiAliasType = AntiAliasType.ADVANCED;
         _text.mouseEnabled = false;
         _text.selectable = false;
         _text.multiline = false;
         _text.height = 20;
         _text.width = TEXT_WIDTH;
         _text.autoSize = TextFieldAutoSize.NONE;
         _text.filters = [new DropShadowFilter(0, 90, 0x000000, 1.0, 2, 2, 2, 1)];

         addChild(_bg);
         addChild(_fill);
         addChild(_text);
         redraw(1.0);
      }

      public function updateHealth(currentHealth:int, maxHealth:int, enemy:Boolean):void
      {
         _enemy = enemy;
         currentHealth = Math.max(0, currentHealth);
         maxHealth = Math.max(0, maxHealth);
         var ratio:Number = maxHealth > 0 ? Math.min(1, Number(currentHealth) / Number(maxHealth)) : 0;
         redraw(ratio);
         _text.text = String(currentHealth);
         alpha = currentHealth > 0 ? 1.0 : 0.55;
         visible = maxHealth > 0;
      }

      private function redraw(ratio:Number):void
      {
         var barX:Number = _enemy ? TEXT_WIDTH + 5 : 0;
         var textX:Number = _enemy ? 0 : BAR_WIDTH + 5;
         var barY:Number = 8;

         _bg.graphics.clear();
         _bg.graphics.lineStyle(1, 0x000000, 0.9);
         _bg.graphics.beginFill(0x151515, 0.82);
         _bg.graphics.drawRect(barX, barY, BAR_WIDTH, BAR_HEIGHT);
         _bg.graphics.endFill();

         _fill.graphics.clear();
         if (ratio > 0)
         {
            _fill.graphics.beginFill(0x67D34A, 1.0);
            if (_enemy)
               _fill.graphics.drawRect(barX + BAR_WIDTH * (1.0 - ratio), barY + 1, BAR_WIDTH * ratio, BAR_HEIGHT - 2);
            else
               _fill.graphics.drawRect(barX + 1, barY + 1, Math.max(0, BAR_WIDTH * ratio - 1), BAR_HEIGHT - 2);
            _fill.graphics.endFill();
         }

         _text.x = textX;
         _text.y = 0;
         var fmt:TextFormat = _text.defaultTextFormat;
         fmt.align = _enemy ? "right" : "left";
         _text.defaultTextFormat = fmt;
         _text.setTextFormat(fmt);
      }
   }
}
