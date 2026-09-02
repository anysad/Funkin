package funkin.ui.debug.stage.components;

#if FEATURE_STAGE_EDITOR
import haxe.ui.components.CheckBox;
import haxe.ui.components.ColorPicker;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.VBox;
import haxe.ui.events.EventType;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;

/**
 * Shared base for properties-panel containers in the Stage Editor.
 */
abstract class BaseSpriteContainer extends VBox implements EditorContainer
{
  public var stageEditorState:StageEditorState;

  public function new(state:StageEditorState)
  {
    super();
    stageEditorState = state;
  }

  /**
   * Populate UI controls from the currently-selected object.
   * Called once after construction by the dispatcher.
   */
  public abstract function loadCurrentObjectData():Void;

  /**
   * Pull the current event's Float value for `fieldName` into `stepper`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentObjectData()`.
   */
  function loadFloatField(stepper:NumberStepper, fieldName:String, defaultValue:Float):Void
  {
    final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
    if (selected == null) return;
    stepper.value = Reflect.field(selected, fieldName) ?? defaultValue;
  }

  /**
   * Wire `stepper.CHANGE` to write its value into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   */
  function bindFloatField(stepper:NumberStepper, fieldName:String):Void
  {
    stepper.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
      if (selected == null) return;
      Reflect.setProperty(selected, fieldName, stepper.value);
    });
  }

  /**
   * Pull the current event's String value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentObjectData()`.
   */
  function loadStringField(field:TextField, fieldName:String, defaultValue:String):Void
  {
    final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
    if (selected == null) return;
    final value:Null<String> = Reflect.field(selected, fieldName);
    field.text = value ?? defaultValue;
  }

  /**
   * Wire `field.CHANGE` to write its text into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   */
  function bindStringField(field:TextField, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
      if (selected == null) return;
      Reflect.setProperty(selected, fieldName, field.text);
    });
  }

  /**
   * Pull the current event's Bool value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentObjectData()`.
   */
  function loadBoolField(field:CheckBox, fieldName:String, defaultValue:Bool):Void
  {
    final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
    if (selected == null) return;
    final value:Null<Bool> = Reflect.field(selected, fieldName);
    field.selected = value ?? defaultValue;
  }

  /**
   * Wire `field.CHANGE` to write its selected state into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   */
  function bindBoolField(field:CheckBox, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
      if (selected == null) return;
      Reflect.setProperty(selected, fieldName, field.selected);
    });
  }

  function loadArrayField<T>(field:{value:T}, fieldName:String, index:Int, defaultValue:T):Void
  {
    final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
    if (selected == null) return;
    final array:Null<Array<T>> = Reflect.field(selected, fieldName);
    if (array == null || array.length < index) return;
    final value:T = array[index];
    field.value = value ?? defaultValue;
  }

  function bindArrayField<T>(field:
    {value:T, registerEvent:(EventType<UIEvent>, UIEvent->Void, ?Int) -> Void}, fieldName:String, index:Int):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
      if (selected == null) return;
      var array:Null<Array<T>> = Reflect.field(selected, fieldName);
      if (array == null || array.length < index) return;
      array[index] = field.value;
      Reflect.setProperty(selected, fieldName, array);
    });
  }

  function loadColorField(field:ColorPicker, fieldName:String, defaultValue:Color):Void
  {
    final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
    if (selected == null) return;
    final value:Null<String> = Reflect.field(selected, fieldName);
    field.currentColor = Color.fromString(value) ?? defaultValue;
  }

  function bindColorField(field:ColorPicker, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      final selected:Null<Dynamic> = stageEditorState.selectedObjectData;
      if (selected == null) return;
      Reflect.setProperty(selected, fieldName, field.currentColor.toHex());
    });
  }
}
#end
