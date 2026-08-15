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
      // Geometry sampled from the reference: a compact ~60px bar made of four
      // narrow equal blocks with small gaps between them.
      public static const SEGMENT_COUNT:int = 4;
      public static const SEGMENT_WIDTH:Number = 14;
      public static const SEGMENT_GAP:Number = 2;
      public static const BAR_WIDTH:Number =
         SEGMENT_WIDTH * SEGMENT_COUNT + SEGMENT_GAP * (SEGMENT_COUNT - 1);
      public static const BAR_HEIGHT:Number = 5;
      public static const TEXT_WIDTH:Number = 32;
      public static const TEXT_GAP:Number = 7;
      public static const TOTAL_WIDTH:Number = BAR_WIDTH + TEXT_WIDTH + TEXT_GAP;
      public static const TOTAL_HEIGHT:Number = 18;

      private static const EMPTY_COLOR:uint = 0x3B4254;
      private static const HEALTH_COLOR:uint = 0xA8E788;
      private static const TEXT_COLOR:uint = 0xDDDDDD;

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

         _text.defaultTextFormat = new TextFormat(
            "$UniversCondC", 13, TEXT_COLOR, false, false, false,
            "", "", "right"
         );
         _text.embedFonts = true;
         _text.antiAliasType = AntiAliasType.ADVANCED;
         _text.mouseEnabled = false;
         _text.selectable = false;
         _text.multiline = false;
         _text.height = TOTAL_HEIGHT;
         _text.width = TEXT_WIDTH;
         _text.autoSize = TextFieldAutoSize.NONE;
         _text.filters = [new DropShadowFilter(1, 90, 0x000000, 0.9, 2, 2, 2, 1)];

         addChild(_bg);
         addChild(_fill);
         addChild(_text);
         redraw(1.0);
         visible = false;
      }

      public function updateHealth(currentHealth:int, maxHealth:int, enemy:Boolean):void
      {
         _enemy = enemy;
         currentHealth = Math.max(0, currentHealth);
         maxHealth = Math.max(0, maxHealth);

         var ratio:Number = maxHealth > 0
            ? Math.min(1, Number(currentHealth) / Number(maxHealth))
            : 0;
         redraw(ratio);
         _text.text = String(currentHealth);
         alpha = currentHealth > 0 ? 1.0 : 0.55;
         // Visibility is intentionally controlled only by HpPanel.as_setVisibility.
      }

      private function redraw(ratio:Number):void
      {
         var barX:Number = _enemy ? TEXT_WIDTH + TEXT_GAP : 0;
         var textX:Number = _enemy ? 0 : BAR_WIDTH + TEXT_GAP;
         var barY:Number = 7;
         var pitch:Number = SEGMENT_WIDTH + SEGMENT_GAP;

         _bg.graphics.clear();
         _fill.graphics.clear();

         for (var i:int = 0; i < SEGMENT_COUNT; ++i)
         {
            var visualIndex:int = _enemy ? SEGMENT_COUNT - 1 - i : i;
            var segmentX:Number = barX + visualIndex * pitch;

            // Empty HP in the source image is blue-grey rather than black.
            _bg.graphics.beginFill(EMPTY_COLOR, 1.0);
            _bg.graphics.drawRect(segmentX, barY, SEGMENT_WIDTH, BAR_HEIGHT);
            _bg.graphics.endFill();

            var localFill:Number = ratio * SEGMENT_COUNT - i;
            localFill = Math.max(0, Math.min(1, localFill));
            if (localFill <= 0)
               continue;

            var fillWidth:Number = SEGMENT_WIDTH * localFill;
            var fillX:Number = segmentX;
            if (_enemy)
               fillX += SEGMENT_WIDTH - fillWidth;

            // The reference uses a thin pale lime strip with a one-pixel dark
            // lower edge left visible from the empty segment behind it.
            _fill.graphics.beginFill(HEALTH_COLOR, 1.0);
            _fill.graphics.drawRect(fillX, barY, fillWidth, BAR_HEIGHT - 1);
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
