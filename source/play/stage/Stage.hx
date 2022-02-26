package play.stage;

import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import modding.IHook;
import play.character.Character.CharacterType;
import play.stage.StageData.StageDataParser;
import util.SortUtil;

/**
 * A Stage is a group of objects rendered in the PlayState.
 * 
 * A Stage is comprised of one or more props, each of which is a FlxSprite.
 */
class Stage extends FlxSpriteGroup implements IHook
{
	public final stageId:String;
	public final stageName:String;

	final _data:StageData;

	public var camZoom:Float = 1.0;

	var namedProps:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	var characters:Map<String, Character> = new Map<String, Character>();

	/**
	 * The Stage elements get initialized at the beginning of the game.
	 * They're used to cache the data needed to build the stage,
	 * then accessed and fleshed out when the stage needs to be built.
	 * 
	 * @param stageId 
	 */
	public function new(stageId:String)
	{
		super();

		this.stageId = stageId;
		_data = StageDataParser.parseStageData(this.stageId);
		this.stageName = _data.name;
	}

	/**
	 * The default stage construction routine. Called when the stage is going to be played in.
	 * Instantiates each prop and adds it to the stage, while setting its parameters.
	 */
	public function buildStage()
	{
		trace('Building stage for display: ${this.stageId}');

		this.camZoom = _data.cameraZoom;
		// this.scrollFactor = new FlxPoint(1, 1);

		for (dataProp in _data.props)
		{
			trace('  Placing prop: ${dataProp.name} (${dataProp.assetPath})');

			var isAnimated = dataProp.animations.length > 0;
			var propSprite = new FlxSprite();

			if (isAnimated)
			{
				// Initalize sprite frames.
				propSprite.frames = Paths.getSparrowAtlas(dataProp.assetPath);
			}
			else
			{
				// Initalize static sprite.
				propSprite.loadGraphic(Paths.image(dataProp.assetPath));
			}

			if (Std.isOfType(dataProp.scale, Array))
			{
				propSprite.scale.set(dataProp.scale[0], dataProp.scale[1]);
			}
			else
			{
				propSprite.scale.set(dataProp.scale);
			}
			propSprite.updateHitbox();

			propSprite.x = dataProp.position[0];
			propSprite.y = dataProp.position[1];

			propSprite.scrollFactor.x = dataProp.scroll[0];
			propSprite.scrollFactor.y = dataProp.scroll[1];

			propSprite.zIndex = dataProp.zIndex;

			for (propAnim in dataProp.animations)
			{
				propSprite.animation.addByPrefix(propAnim.name, propAnim.prefix, propAnim.frameRate, propAnim.loop);
			}

			if (dataProp.startingAnimation != null)
			{
				propSprite.animation.play(dataProp.startingAnimation);
			}

			if (dataProp.name != null)
			{
				namedProps.set(dataProp.name, propSprite);
			}

			trace('    Prop placed.');
			this.add(propSprite);
		}

		this.refresh();
	}

	/**
	 * Refreshes the stage, by redoing the render order of all props.
	 * It does this based on the `zIndex` of each prop.
	 */
	public function refresh()
	{
		sort(SortUtil.byZIndex, FlxSort.ASCENDING);
		trace('Stage sorted by z-index');
	}

	/**
	 * A function that gets called every frame.
	 * @param elapsed The number of 
	 */
	public function onUpdate(elapsed:Float):Void
	{
		// Override me in your scripted stage to perform custom behavior!
		// trace('Stage.onUpdate(${elapsed})');
	}

	/**
	 * Adjusts the position and other properties of the soon-to-be child of this sprite group.
	 * Private helper to avoid duplicate code in `add()` and `insert()`.
	 *
	 * @param	Sprite	The sprite or sprite group that is about to be added or inserted into the group.
	 */
	override function preAdd(Sprite:FlxSprite):Void
	{
		var sprite:FlxSprite = cast Sprite;
		sprite.x += x;
		sprite.y += y;
		sprite.alpha *= alpha;
		// Don't override scroll factors.
		// sprite.scrollFactor.copyFrom(scrollFactor);
		sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

		if (clipRect != null)
			clipRectTransform(sprite, clipRect);
	}

	/**
	 * A function that gets called once per step in the song.
	 * @param curStep The current step number.
	 */
	public function onStepHit(curStep:Int):Void
	{
		// Override me in your scripted stage to perform custom behavior!
	}

	/**
	 * A function that gets called once per beat in the song (once every four steps).
	 * @param curStep The current beat number.
	 */
	public function onBeatHit(curBeat:Int):Void
	{
		// Override me in your scripted stage to perform custom behavior!
		// trace('Stage.onBeatHit(${curBeat})');
	}

	/**
	 * Used by the PlayState to add a character to the stage.
	 */
	public function addCharacter(character:Character, charType:CharacterType)
	{
		// Apply position and z-index.
		switch (charType)
		{
			case BF:
				this.characters.set("bf", character);
				character.zIndex = _data.characters.bf.zIndex;
				character.x = _data.characters.bf.position[0];
				character.y = _data.characters.bf.position[1];
			case GF:
				this.characters.set("gf", character);
				character.zIndex = _data.characters.gf.zIndex;
				character.x = _data.characters.gf.position[0];
				character.y = _data.characters.gf.position[1];
			case DAD:
				this.characters.set("dad", character);
				character.zIndex = _data.characters.dad.zIndex;
				character.x = _data.characters.dad.position[0];
				character.y = _data.characters.dad.position[1];
			default:
				this.characters.set(character.curCharacter, character);
		}

		// Add the character to the scene.
		this.add(character);
	}

	/**
	 * Retrieves a given character from the stage.
	 * @param id 
	 * @return Character
	 */
	public function getCharacter(id:String):Character
	{
		return this.characters.get(id);
	}

	public function getBoyfriend():Character
	{
		return getCharacter('bf');
	}

	public function getGirlfriend():Character
	{
		return getCharacter('gf');
	}

	public function getDad():Character
	{
		return getCharacter('dad');
	}

	/**
	 * Retrieve a specific prop by the name assigned in the JSON file.
	 * @param name The name of the prop to retrieve.
	 * @return The corresponding FlxSprite.
	 */
	public function getNamedProp(name:String):FlxSprite
	{
		return this.namedProps.get(name);
	}

	/**
	 * Retrieve a list of all the asset paths required to load the stage.
	 * Override this in a scripted class to ensure that all necessary assets are loaded!
	 * 
	 * @return An array of file names.
	 */
	public function fetchAssetPaths():Array<String>
	{
		var result:Array<String> = [];
		for (dataProp in _data.props)
		{
			result.push(Paths.image(dataProp.assetPath));
		}
		return result;
	}

	/**
	 * Perform cleanup for when you are leaving the level.
	 */
	public override function kill()
	{
		super.kill();

		for (prop in this.namedProps)
		{
			prop.destroy();
		}
		namedProps.clear();

		for (char in this.characters)
		{
			char.destroy();
		}
		characters.clear();

		for (sprite in this.group)
		{
			sprite.destroy();
		}
		group.clear();
	}

	/**
	 * Perform cleanup for when you are destroying the stage
	 * and removing all its data from cache.
	 * 
	 * Call this ONLY when you are performing a hard cache clear.
	 */
	public override function destroy()
	{
		super.destroy();
	}
}
