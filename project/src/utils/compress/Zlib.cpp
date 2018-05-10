#include <utils/compress/Zlib.h>
#include <zlib.h>


namespace lime {
	
	
	void Zlib::Compress (ZlibType type, Bytes* data, Bytes* result) {
		
		int windowBits = 15;
		
		switch (type) {
			
			case DEFLATE: windowBits = -15; break;
			case GZIP: windowBits = 31; break;
			default: break;
			
		}
		
		z_stream* stream = (z_stream*)malloc (sizeof (z_stream));
		stream->zalloc = Z_NULL;
		stream->zfree = Z_NULL;
		stream->opaque = Z_NULL;
		
		int ret = 0;
		
		if ((ret = deflateInit2 (stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, windowBits, 8, Z_DEFAULT_STRATEGY) != Z_OK)) {
			
			//val_throw (stream->msg);
			free (stream);
			return;
			
		}
		
		int bufferSize = deflateBound (stream, data->Length ());
		char* buffer = (char*)malloc (bufferSize);
		
		stream->next_in = (Bytef*)data->Data ();
		stream->next_out = (Bytef*)buffer;
		stream->avail_in = data->Length ();
		stream->avail_out = bufferSize;
		
		if ((ret = deflate (stream, Z_FINISH)) < 0) {
			
			//if (stream && stream->msg) printf ("%s\n", stream->msg);
			//val_throw (stream->msg);
			deflateEnd (stream);
			free (stream);
			free (buffer);
			return;
			
		}
		
		int size = bufferSize - stream->avail_out;
		result->Resize (size);
		memcpy (result->Data (), buffer, size);
		deflateEnd (stream);
		free (stream);
		free (buffer);
		
		return;
		
	}
	
	
	void Zlib::Decompress (ZlibType type, Bytes* data, Bytes* result) {
		
		int windowBits = 15;
		
		switch (type) {
			
			case DEFLATE: windowBits = -15; break;
			case GZIP: windowBits = 31; break;
			default: break;
			
		}
		
		z_stream* stream = (z_stream*)malloc (sizeof (z_stream));
		stream->zalloc = Z_NULL;
		stream->zfree = Z_NULL;
		stream->opaque = Z_NULL;
		
		int ret = 0;
		
		if ((ret = inflateInit2 (stream, windowBits) != Z_OK)) {
			
			//val_throw (stream->msg);
			inflateEnd (stream);
			free (stream);
			return;
			
		}
		
		int chunkSize = 1 << 16;
		int readSize = 0;
		Bytef* sourcePosition = data->Data ();
		int destSize = 0;
		int readTotal = 0;
		
		Bytef* buffer = (Bytef*)malloc (chunkSize);
		
		stream->avail_in = data->Length ();
		stream->next_in = data->Data ();
		
		if (stream->avail_in > 0) {
			
			do {
				
				stream->avail_out = chunkSize;
				stream->next_out = buffer;
				
				ret = inflate (stream, Z_NO_FLUSH);
				
				if (ret == Z_STREAM_ERROR) {
					
					inflateEnd (stream);
					free (stream);
					free (buffer);
					return;
					
				}
				
				switch (ret) {
					
					case Z_NEED_DICT:
						ret = Z_DATA_ERROR;
					case Z_DATA_ERROR:
					case Z_MEM_ERROR:
						inflateEnd (stream);
						free (stream);
						free (buffer);
						return;
					
				}
				
				readSize = chunkSize - stream->avail_out;
				readTotal += readSize;
				
				result->Resize (readTotal);
				memcpy (result->Data () + readTotal - readSize, buffer, readSize);
				
				sourcePosition += readSize;
				
			} while (stream->avail_out == 0);
			
		}
		
		inflateEnd (stream);
		free (stream);
		free (buffer);
		
		return;
		
	}
	
	
}