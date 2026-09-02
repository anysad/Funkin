package funkin.ui.debug.stage.components;

#if FEATURE_STAGE_EDITOR
/**
 * Common interface for stage-editor properties-panel containers.
 *
 * Each container is keyed in `StageEditorPropertiesPanelHandler.containers`
 * by an object data type (e.g. `StageDataProp`, `StageDataCharacter`) and is
 * instantiated when the user selects an object of that kind in the viewport or
 * in the object list.
 *
 */
interface EditorContainer
{
  /**
   * Pull the currently-selected object's field values into the UI controls.
   * Called once after construction by the dispatcher.
   */
  public function loadCurrentObjectData():Void;
}
#end
