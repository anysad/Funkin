package funkin.ui.debug.stage;

#if FEATURE_STAGE_EDITOR
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.assets.FunkinAssetCache;
import funkin.data.character.CharacterData.CharacterDataParser;
import flixel.util.FlxSort;
import funkin.graphics.FunkinAnimationController;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayState;
import funkin.util.SortUtil;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
import funkin.ui.debug.stage.commands.StageEditorCommand;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.preload.hotreload.HotReloadState.HotReloadStateParams;
import funkin.util.FileUtil;
import funkin.util.InputUtil;
import funkin.util.MouseUtil;
import funkin.util.SortUtil;
import funkin.util.WindowUtil;
import funkin.util.assets.SoundUtil;
// import funkin.util.file.FNFSUtil.FNFSData;
import funkin.util.logging.CrashHandler;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.backend.flixel.MouseHelper;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.Panel;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuOptionBox;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.Toolkit;
import haxe.ui.focus.FocusManager;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

using StringTools;

/**
 * A state dedicated to allowing the user to create and edit stages.
 * Built with HaxeUI for use by both developer and modders.
 *
 * @author anysad
 * @author KoloInDaCrib
 */

// @:nullSafety // fucking, stupid, haxeui building macro!
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/stage-editor/main-view.xml'))
class StageEditorState extends UIState implements ConsoleClass
{
  /**
   * CONSTANTS
   */
  // ==============================

  /**
   * The path to save backups to, when the editor is closed unexpectedly.
   */
  public static final BACKUPS_PATH:String = './backups/stages/';

  /**
   * The current instance of the Stage Editor.
   */
  public static var instance:StageEditorState = null;

  /**
   * INSTANCE DATA
   */
  // ==============================

  @:bind(menubarItemCharacters.selected)
  var showCharacters(default, set):Bool = true;

  function set_showCharacters(value:Bool):Bool
  {
    showCharacters = value;
    // update visibility
    return showCharacters;
  }

  @:bind(menubarItemObjectName.selected)
  var showObjectName:Bool = false;

  @:bind(menubarItemFloorLines.selected)
  var showFloorLines(default, set):Bool = false;

  function set_showFloorLines(value:Bool):Bool
  {
    showFloorLines = value;
    // update visibility
    return showFloorLines;
  }

  @:bind(menubarItemPositionMarkers.selected)
  var showPositionMarkers(default, set):Bool = false;

  function set_showPositionMarkers(value:Bool):Bool
  {
    showPositionMarkers = value;
    // update visibility
    return showPositionMarkers;
  }

  @:bind(menubarItemCameraBounds.selected)
  var showCameraBounds(default, set):Bool = false;

  function set_showCameraBounds(value:Bool):Bool
  {
    showCameraBounds = value;
    // update visibility
    return showCameraBounds;
  }

  // public var selectedObject(default, set):Null<Dynamic> = null;

  // function set_selectedObject(value:Null<Dynamic>):Null<Dynamic>
  // {
  //   selectedObject = value;
  //   selectedObjectData = value == null ? null : value.data;
  //   return selectedObject;
  // }

  public var selectedObjectData:Null<Dynamic> = null;

  /**
   * Whether the user is focused on an input in the Haxe UI, and inputs are being fed into it.
   * If the user clicks off the input, focus will leave.
   */
  var isHaxeUIFocused(get, never):Bool;

  function get_isHaxeUIFocused():Bool
  {
    return FocusManager.instance.focus != null;
  }

  /**
   * Whether the user's mouse cursor is hovering over a SOLID component of the HaxeUI.
   * If so, we can ignore certain mouse events underneath.
   */
  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  /**
   * The camera that the HUD is rendered to.
   */
  var camHUD:FlxCamera;

  /**
   * The camera that the game underneath the HUD is rendered to.
   */
  var camGame:FlxCamera;

  /**
   * The value of `isCursorOverHaxeUI` from the previous frame.
   * This is useful because we may have just clicked a menu item, causing the menu to disappear.
   */
  var wasCursorOverHaxeUI:Bool = false;

  /**
   * HAXEUI COMPONENTS
   */
  // ==============================

  /**
   * The properties panel on the right side.
   * Holds the properties container, which gets swapped when a different object type is selected.
   */
  var propertiesPanel:Panel;

  // Auto-save

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  // History

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<StageEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<StageEditorCommand> = [];

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty(default, set):Bool = true;

  function set_commandHistoryDirty(value:Bool):Bool
  {
    commandHistoryDirty = value;

    if (value)
    {
      // updateUndoRedoMenuItems();
      commandHistoryDirty = false;
    }

    return commandHistoryDirty;
  }

  // var shouldShowBackupAvailableDialog(get, set):Bool;

  // function get_shouldShowBackupAvailableDialog():Bool
  // {
  //   return Save.instance.stageEditorHasBackup.value && StageEditorImportExportHandler.getLatestBackupPath() != null;
  // }

  // function set_shouldShowBackupAvailableDialog(value:Bool):Bool
  // {
  //   return Save.instance.stageEditorHasBackup.value = value;
  // }


  /**
   * LIFE CYCLE FUNCTIONS
   */
  // ==============================

  /**
   * The params which were passed in when the Stage Editor was initialized.
   */
  var params:Null<StageEditorParams>;

  public function new(?params:StageEditorParams)
  {
    super();
    this.params = params;
  }

  override public function create():Void
  {
    WindowManager.instance.reset();
    instance = this;

    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Stage Editor");

    // loadPreferences();

    // NOTE: Always use `FunkinCamera` instead of `FlxCamera` when manually instantiating cameras.
    // This allows the blend mode shader used on some devices to work properly.
    camGame = new FunkinCamera();
    camGame.bgColor.alpha = 0;
    camHUD = new FunkinCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame); // Cam game is default
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    super.create();
    root.scrollFactor.set();
    root.cameras = [camHUD];
    root.width = FlxG.width;
    root.height = FlxG.height;

    // WindowUtil.windowExit.add(windowClose);
    // CrashHandler.errorSignal.add(autosavePerCrash);
    // CrashHandler.criticalErrorSignal.add(autosavePerCrash);

    Cursor.show();
    FunkinSound.playMusic('ui/editors/chart-editor/artistic-expression/artistic-expression', {
      startingVolume: 0.0
    });
    FlxG.sound.music.fadeIn(10, 0, 1);
  }
}

/**
 * Parameters to initialize the Stage Editor with.
 * Most of these are optional.
 */
typedef StageEditorParams =
{
  // STAGE LOADING

  /**
   * If non-null, load an existing song directly from a file path.
   */
  var ?loadFromPath:String;

  /**
   * If non-null, load an existing song directly from the game's assets.
   */
  var ?loadFromTemplate:String;

  /**
   * If non-null, load from existing FNFSData.
   */
  // var ?loadFromFNFSData:FNFSData;

  // CHARACTERS

  /**
   * If non-null, load this character as Boyfriend.
   */
  var ?targetBfCharacter:String;

  /**
   * If non-null, load this character as Girlfriend.
   */
  var ?targetGfCharacter:String;

  /**
   * If non-null, load this character as Opponent.
   */
  var ?targetOpponentCharacter:String;
};

#end
