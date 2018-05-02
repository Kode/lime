package lime.system;


#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

import lime._backend.kha.KhaManifestResources;

@:access(lime.app.Application)
@:access(lime.system.System)
@:access(openfl.display.Stage)


@:dox(hide) class KhaMain {
	
	
	#if (!macro && kha)
	
	
	public static function main () {
		
		kha.System.init({title: "OpenFL Test", width: 800, height: 600}, function () {
			kha.Assets.loadEverything(function () {
				var projectName = "::APP_FILE::";
				
				var config = {
					
					build: "::meta.buildNumber::",
					company: "::meta.company::",
					file: "::APP_FILE::",
					fps: 60,
					name: "::meta.title::",
					orientation: "::WIN_ORIENTATION::",
					packageName: "::meta.packageName::",
					version: "::meta.version::",
					windows: [
						{
							allowHighDPI: true,
							alwaysOnTop: false,
							antialiasing: 0,
							background: null,
							borderless: false,
							colorDepth: 32,
							depthBuffer: true,
							display: 0,
							fullscreen: false,
							hardware: true,
							height: 600,
							hidden: #if munit true #else false #end,
							maximized: false,
							minimized: false,
							parameters: [],
							resizable: false,
							stencilBuffer: true,
							title: "OpenFL Test",
							vsync: true,
							width: 800,
							x: 100,
							y: 100
						}
					]
					
				};
				
				lime.system.System.__registerEntryPoint (projectName, create, config);
				
				#if (hxtelemetry && !macro)
				var telemetry = new hxtelemetry.HxTelemetry.Config ();
				telemetry.allocations = ::if (config.hxtelemetry != null)::("::config.hxtelemetry.allocations::" == "true")::else::true::end::;
				telemetry.host = ::if (config.hxtelemetry != null)::"::config.hxtelemetry.host::"::else::"localhost"::end::;
				telemetry.app_name = config.name;
				Reflect.setField (config, "telemetry", telemetry);
				#end
				
				#if (js && html5)
				#if (munit || utest)
				lime.system.System.embed (projectName, null, ::WIN_WIDTH::, ::WIN_HEIGHT::, config);
				#end
				#else
				create (config);
				#end
			});
		});

	}
	
	
	public static function create (config:lime.app.Config):Void {
		
		var app = new openfl.display.Application ();
		app.create (config);
		
		KhaManifestResources.init (config);
		
		var preloader = getPreloader ();
		app.setPreloader (preloader);
		preloader.create (config);
		preloader.onComplete.add (start.bind (app.window.stage));
		
		for (library in KhaManifestResources.preloadLibraries) {
			
			preloader.addLibrary (library);
			
		}
		
		for (name in KhaManifestResources.preloadLibraryNames) {
			
			preloader.addLibraryName (name);
			
		}
		
		preloader.load ();
		
		var result = app.exec ();
				
	}
	
	
	public static function start (stage:openfl.display.Stage):Void {
		
		try {
			
			KhaMain.getEntryPoint ();
			
			stage.dispatchEvent (new openfl.events.Event (openfl.events.Event.RESIZE, false, false));
			
			if (stage.window.fullscreen) {
				
				stage.dispatchEvent (new openfl.events.FullScreenEvent (openfl.events.FullScreenEvent.FULL_SCREEN, false, false, true, true));
				
			}
			
		} catch (e:Dynamic) {
			
			#if !display
			stage.__handleError (e);
			#end
			
		}
		
	}
	
	
	#end
	
	
	macro public static function getEntryPoint () {
		
		var hasMain = false;
		
		switch (Context.follow (Context.getType ("Main"))) {
			
			case TInst (t, params):
				
				var type = t.get ();
				
				for (method in type.statics.get ()) {
					
					if (method.name == "main") {
						
						hasMain = true;
						break;
						
					}
					
				}
				
				if (hasMain) {
					
					return Context.parse ("@:privateAccess Main.main ()", Context.currentPos ());
					
				} else if (type.constructor != null) {
					
					return macro {
						
						var current = stage.getChildAt (0);
						
						if (current == null || !Std.is (current, openfl.display.DisplayObjectContainer)) {
							
							current = new openfl.display.MovieClip ();
							stage.addChild (current);
							
						}
						
						new DocumentClass (cast current);
						
					};
					
				} else {
					
					Context.fatalError ("Main class \"Main\" has neither a static main nor a constructor.", Context.currentPos ());
					
				}
				
			default:
				
				Context.fatalError ("Main class \"Main\" isn't a class.", Context.currentPos ());
			
		}
		
		return null;
		
	}
	
	
	macro public static function getPreloader () {
		
		return macro { new openfl.display.Preloader (new openfl.display.Preloader.DefaultPreloader ()); };
		
	}
	
	
	#if !macro
	@:noCompletion @:dox(hide) public static function __init__ () {
		
		var init = lime.app.Application;
		
	}
	#end
	
	
}


#if !macro


@:build(lime.system.DocumentClass.build())
@:keep @:dox(hide) class DocumentClass extends Main {}


#else


class DocumentClass {
	
	
	macro public static function build ():Array<Field> {
		
		var classType = Context.getLocalClass ().get ();
		var searchTypes = classType;
		
		while (searchTypes != null) {
			
			if (searchTypes.module == "openfl.display.DisplayObject" || searchTypes.module == "flash.display.DisplayObject") {
				
				var fields = Context.getBuildFields ();
				
				var method = macro {
					
					current.addChild (this);
					super ();
					dispatchEvent (new openfl.events.Event (openfl.events.Event.ADDED_TO_STAGE, false, false));
					
				}
				
				fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: [ { name: "current", opt: false, type: macro :openfl.display.DisplayObjectContainer, value: null } ], expr: method, params: [], ret: macro :Void }), pos: Context.currentPos () });
				
				return fields;
				
			}
			
			if (searchTypes.superClass != null) {
				
				searchTypes = searchTypes.superClass.t.get ();
				
			} else {
				
				searchTypes = null;
				
			}
			
		}
		
		return null;
		
	}
	
	
}


#end