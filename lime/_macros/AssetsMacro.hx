package lime._macros;


#if macro
import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

#if (macro && !display)
import sys.io.File;
import sys.FileSystem;
#end


class AssetsMacro {
	
	
	#if !macro
	
	
	macro public static function cacheVersion () {}
	
	
	#else
	
	
	private static var base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var base64Encoder:BaseCode;
	
	
	private static function base64Encode (bytes:Bytes):String {
		
		var extension = switch (bytes.length % 3) {
			
			case 1: "==";
			case 2: "=";
			default: "";
			
		}
		
		if (base64Encoder == null) {
			
			base64Encoder = new BaseCode (Bytes.ofString (base64Chars));
			
		}
		
		return base64Encoder.encodeBytes (bytes).toString () + extension;
		
	}
	
	
	macro public static function cacheVersion () {
		
		return macro Std.int (Math.random () * 1000000);
		
	}
	
	
	macro public static function embedBytes ():Array<Field> {
		
		var fields = embedData (":file");
		
		if (fields != null) {
			
			#if !display
			
			var constructor = macro {
				
				#if lime_console
				throw "not implemented";
				#else
				var bytes = haxe.Resource.getBytes (resourceName);
				#if html5
				super (bytes.b.buffer);
				#else
				super (bytes.length, bytes.b);
				#end
				#end
				
			};
			
			var args = [ { name: "length", opt: true, type: macro :Int }, { name: "bytesData", opt: true, type: macro :haxe.io.BytesData } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedByteArray ():Array<Field> {
		
		var fields = embedData (":file");
		
		if (fields != null) {
			
			#if !display
			
			var constructor = macro {
				
				super ();
				
				#if lime_console
				throw "not implemented";
				#else
				var bytes = haxe.Resource.getBytes (resourceName);
				__fromBytes (bytes);
				#end
				
			};
			
			var args = [ { name: "length", opt: true, type: macro :Int, value: macro 0 } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
	private static function embedData (metaName:String, encode:Bool = false):Array<Field> {
		
		#if !display
		
		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		
		for (meta in metaData) {
			
			if (meta.name == metaName) {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							#if lime_console
							
							var fieldValue = {
								pos: position,
								expr: EConst(CString(filePath))
							};
							fields.push ({
								kind: FVar(macro :String, fieldValue),
								name: "filePath",
								access: [ APrivate, AStatic ],
								pos: position
							});
							
							#else
							
							var path = filePath;
							
							if (path == "") return null;
							if (path == null) return null;
							
							if (!FileSystem.exists (filePath)) {
								
								path = Context.resolvePath (filePath);
								
							}
							
							if (!FileSystem.exists (path) || FileSystem.isDirectory (path)) {
								
								return null;
								
							}
							
							var bytes = File.getBytes (path);
							var resourceName = "__ASSET__" + metaName + "_" + (classType.pack.length > 0 ? classType.pack.join ("_") + "_" : "") + classType.name;
							
							if (Context.getResources ().exists (resourceName)) {
								
								return null;
								
							}
							
							if (encode) {
								
								var resourceType = "image/png";
								
								if (bytes.get (0) == 0xFF && bytes.get (1) == 0xD8) {
									
									resourceType = "image/jpg";
									
								} else if (bytes.get (0) == 0x47 && bytes.get (1) == 0x49 && bytes.get (2) == 0x46) {
									
									resourceType = "image/gif";
									
								}
								
								var fieldValue = { pos: position, expr: EConst(CString(resourceType)) };
								fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceType", access: [ APrivate, AStatic ], pos: position });
								
								var base64 = base64Encode (bytes);
								Context.addResource (resourceName, Bytes.ofString (base64));
								
							} else {
								
								Context.addResource (resourceName, bytes);
								
							}
							
							var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
							fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APrivate, AStatic ], pos: position });
							
							#end
							
							return fields;
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		#end
		
		return null;
		
	}
	
	
	macro public static function embedFont ():Array<Field> {

		var fields = null;
		
		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var path = "";
		var glyphs = "32-255";
		
		#if !display
		
		for (meta in metaData) {
			
			if (meta.name == ":font") {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							path = filePath;
							
							if (!sys.FileSystem.exists(filePath)) {
								
								path = Context.resolvePath (filePath);
								
							}
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		if (path != null && path != "") {
			
			#if lime_console
			throw "not implemented";
			#end
			
			#if html5
			Sys.command ("haxelib", [ "run", "lime", "generate", "-font-hash", sys.FileSystem.fullPath(path) ]);
			path += ".hash";
			#end
			
			var bytes = File.getBytes (path);
			var resourceName = "LIME_font_" + (classType.pack.length > 0 ? classType.pack.join ("_") + "_" : "") + classType.name;
			
			Context.addResource (resourceName, bytes);
			
			for (field in fields) {
				
				if (field.name == "new") {
					
					fields.remove (field);
					break;
					
				}
				
			}
			
			var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
			fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APublic, AStatic ], pos: position });
			
			var constructor = macro {
				
				super ();
				
				__fromBytes (haxe.Resource.getBytes (resourceName));
				
			};
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: [], expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			return fields;
			
		}
		
		#end
		
		return fields;
		
	}
	
	
	macro public static function embedImage ():Array<Field> {
		
		#if html5
		var fields = embedData (":image", true);
		#else
		var fields = embedData (":image");
		#end
		
		if (fields != null) {
			
			#if !display
			
			var constructor = macro { 
				
				#if html5
				
				super ();
				
				if (preload != null) {
					
					var buffer = new lime.graphics.ImageBuffer ();
					buffer.__srcImage = preload;
					buffer.width = preload.width;
					buffer.width = preload.height;
					
					__fromImageBuffer (buffer);
					
				} else {
					
					__fromBase64 (haxe.Resource.getString (resourceName), resourceType, function (image) {
						
						if (preload == null) {
							
							preload = image.buffer.__srcImage;
							
						}
						
						if (onload != null) {
							
							onload (image);
							
						}
						
					});
					
				}
				
				#else
				
				super ();
				
				#if lime_console
				throw "not implemented";
				#else
				__fromBytes (haxe.Resource.getBytes (resourceName), null);
				#end
				
				#end
				
			};
			
			var args = [ { name: "buffer", opt: true, type: macro :lime.graphics.ImageBuffer, value: null }, { name: "offsetX", opt: true, type: macro :Int, value: null }, { name: "offsetY", opt: true, type: macro :Int, value: null }, { name: "width", opt: true, type: macro :Int, value: null }, { name: "height", opt: true, type: macro :Int, value: null }, { name: "color", opt: true, type: macro :Null<Int>, value: null }, { name: "type", opt: true, type: macro :lime.graphics.ImageType, value: null } ];
			
			#if html5
			args.push ({ name: "onload", opt: true, type: macro :Dynamic, value: null });
			fields.push ({ kind: FVar(macro :js.html.Image, null), name: "preload", doc: null, meta: [], access: [ APublic, AStatic ], pos: Context.currentPos() });
			#end
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedSound ():Array<Field> {
		
		var fields = embedData (":sound");
		
		if (fields != null) {
			
			#if (openfl && !html5 && !display) // CFFILoader.h(248) : NOT Implemented:api_buffer_data
			
			var constructor = macro { 
				
				super();
				
				#if lime_console
				throw "not implemented";
				#else
				var byteArray = openfl.utils.ByteArray.fromBytes (haxe.Resource.getBytes(resourceName));
				loadCompressedDataFromByteArray(byteArray, byteArray.length, forcePlayAsMusic);
				#end
				
			};
			
			var args = [ { name: "stream", opt: true, type: macro :openfl.net.URLRequest, value: null }, { name: "context", opt: true, type: macro :openfl.media.SoundLoaderContext, value: null }, { name: "forcePlayAsMusic", opt: true, type: macro :Bool, value: macro false } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
	#end
	
	
}