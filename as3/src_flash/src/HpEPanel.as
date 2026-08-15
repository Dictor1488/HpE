package
{
   import com.dictor.hpe.battle.HpPanel;
   import com.dictor.hpe.injector.AbstractViewInjector;
   import com.dictor.hpe.injector.IAbstractInjector;

   public class HpEPanel extends AbstractViewInjector implements IAbstractInjector
   {
      public function HpEPanel()
      {
         super();
      }

      override public function get componentUI():Class
      {
         return HpPanel;
      }

      override public function get componentName():String
      {
         return "hpePlayerPanel";
      }
   }
}
