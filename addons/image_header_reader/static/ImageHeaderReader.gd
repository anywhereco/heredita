class_name ImageHeaderReader
extends Node

enum Errors {
	FILE_TOO_SMALL,
	INVALID_SIGNATURE,
	INVALID_CHUNK,
	DIMENSIONS_NOT_FOUND,
}

static var _readers: Dictionary[StringName, FileTypeReader] = {
	&"png": PngReader.new(),
	&"jpg": JpegReader.new(),
	&"webp": WebpReader.new(),
	&"bmp": BmpReader.new()
}

@abstract class FileTypeReader:
	## Will return Vector2i(-1, [error code]) in the case of an error
	@abstract func read_resolution(data: StreamPeerBuffer) -> Vector2i

class PngReader extends FileTypeReader:
	func read_resolution(data: StreamPeerBuffer) -> Vector2i:
		if data.get_size() < 24:
			return Vector2i(-1, Errors.FILE_TOO_SMALL)
		
		data.big_endian = true
		data.seek(0)
		
		# Verify standard 8-byte PNG signature: 89 50 4E 47 0D 0A 1A 0A
		if (data.get_u8() != 0x89 or data.get_u8() != 0x50 or 
			data.get_u8() != 0x4E or data.get_u8() != 0x47 or 
			data.get_u8() != 0x0D or data.get_u8() != 0x0A or 
			data.get_u8() != 0x1A or data.get_u8() != 0x0A):
			return Vector2i(-1, Errors.INVALID_SIGNATURE)
			
		# Verify first critical chunk is "IHDR" (ASCII: 49 48 44 52)
		data.seek(12)
		if (data.get_u8() != 0x49 or data.get_u8() != 0x48 or 
			data.get_u8() != 0x44 or data.get_u8() != 0x52):
			return Vector2i(-1, Errors.INVALID_CHUNK)
			
		data.seek(16)
		return Vector2i(
			data.get_u32(),
			data.get_u32()
		)

class JpegReader extends FileTypeReader:
	func read_resolution(data: StreamPeerBuffer) -> Vector2i:
		var file_size = data.get_size()
		if file_size < 4:
			return Vector2i(-1, Errors.FILE_TOO_SMALL)
			
		data.big_endian = true
		
		# verify jpeg soi marker
		data.seek(0)
		if data.get_u8() != 0xFF or data.get_u8() != 0xD8:
			return Vector2i(-1, Errors.INVALID_SIGNATURE)
			
		var pos = 2
		while pos < file_size:
			data.seek(pos)
			if data.get_u8() != 0xFF:
				pos += 1
				continue
				
			# skip extra padding 0xFF bytes
			pos += 1
			data.seek(pos)
			while pos < file_size and data.get_u8() == 0xFF:
				pos += 1
				data.seek(pos)
				
			if pos >= file_size:
				break
				
			# read the marker byte
			data.seek(pos)
			var marker = data.get_u8()
			pos += 1
			
			# stop parsing if we encounter start of scan or end of image
			if marker == 0xDA or marker == 0xD9:
				break
				
			# check for start of frame markers: 0xC0 through 0xCF (but not C4, C8, CC)
			var is_sof = (marker >= 0xC0 and marker <= 0xCF) and (marker != 0xC4 and marker != 0xC8 and marker != 0xCC)
			if is_sof:
				if pos + 7 > file_size:
					return Vector2i(-1, Errors.INVALID_CHUNK)
					
				# skip segment length (2 bytes) and data precision (1 byte)
				data.seek(pos + 3)
				var height = data.get_u16()
				var width = data.get_u16()
				return Vector2i(width, height)
				
			# skip other segments by reading and jumping past their length fields
			var has_length = (marker != 0xD8) and (marker != 0xD9) and (marker != 0x01) and (marker < 0xD0 or marker > 0xD7)
			if has_length:
				if pos + 2 > file_size:
					break
				data.seek(pos)
				var seg_length = data.get_u16()
				pos += seg_length
				
		return Vector2i(-1, Errors.DIMENSIONS_NOT_FOUND)


class WebpReader extends FileTypeReader:
	func _get_u24_le(data: StreamPeerBuffer) -> int:
		var b0 = data.get_u8()
		var b1 = data.get_u8()
		var b2 = data.get_u8()
		return b0 | (b1 << 8) | (b2 << 16)

	func read_resolution(data: StreamPeerBuffer) -> Vector2i:
		var file_size = data.get_size()
		if file_size < 12:
			return Vector2i(-1, Errors.FILE_TOO_SMALL)
		
		data.big_endian = false
		data.seek(0)
		
		# "RIFF"
		if data.get_u8() != 0x52 or data.get_u8() != 0x49 or data.get_u8() != 0x46 or data.get_u8() != 0x46:
			return Vector2i(-1, Errors.INVALID_SIGNATURE)
		
		# skip file size
		data.seek(8)
		
		# "WEBP"
		if data.get_u8() != 0x57 or data.get_u8() != 0x45 or data.get_u8() != 0x42 or data.get_u8() != 0x50:
			return Vector2i(-1, Errors.INVALID_SIGNATURE)
		
		var pos = 12
		while pos + 8 <= file_size:
			data.seek(pos)
			
			# fourcc
			var c0 = data.get_u8()
			var c1 = data.get_u8()
			var c2 = data.get_u8()
			var c3 = data.get_u8()
			
			var chunk_size = data.get_u32()
			var chunk_data_offset = pos + 8
			
			if chunk_data_offset + chunk_size > file_size:
				break
			
			# "VP8X" (I don't even think this one is supported in Godot)
			if c0 == 0x56 and c1 == 0x50 and c2 == 0x38 and c3 == 0x58:
				if chunk_size < 10:
					return Vector2i(-1, Errors.INVALID_CHUNK)
				
				# 24-bit integers(??), chunk offset + 4 and + 7
				data.seek(chunk_data_offset + 4)
				var width = _get_u24_le(data) + 1
				var height = _get_u24_le(data) + 1
				return Vector2i(width, height)
			
			# "VP8L" (lossless)
			elif c0 == 0x56 and c1 == 0x50 and c2 == 0x38 and c3 == 0x4C:
				if chunk_size < 5:
					return Vector2i(-1, Errors.INVALID_CHUNK)
				
				data.seek(chunk_data_offset)
				if data.get_u8() != 0x2F: # Signature must be 0x2F
					return Vector2i(-1, Errors.INVALID_SIGNATURE)
				
				var b0 = data.get_u8()
				var b1 = data.get_u8()
				var b2 = data.get_u8()
				var b3 = data.get_u8()
				
				# Extract 14-bit width-1 and height-1 fields
				var width = (b0 | ((b1 & 0x3F) << 8)) + 1
				var height = (((b1 & 0xC0) >> 6) | (b2 << 2) | ((b3 & 0x0F) << 10)) + 1
				return Vector2i(width, height)
			
			# "VP8 " (yes with a space)
			elif c0 == 0x56 and c1 == 0x50 and c2 == 0x38 and c3 == 0x20:
				if chunk_size < 10:
					return Vector2i(-1, Errors.INVALID_CHUNK)
				
				# sync code: 9D 01 2A
				data.seek(chunk_data_offset + 3)
				if data.get_u8() != 0x9D or data.get_u8() != 0x01 or data.get_u8() != 0x2A:
					return Vector2i(-1, Errors.INVALID_SIGNATURE)
				
				# 16-bit integers but masked to 14 bits
				var width = data.get_u16() & 0x3FFF
				var height = data.get_u16() & 0x3FFF
				return Vector2i(width, height)
			
			# advance to next chunk (padded to even offset)
			pos = chunk_data_offset + chunk_size
			if chunk_size % 2 != 0:
				pos += 1
		
		return Vector2i(-1, Errors.DIMENSIONS_NOT_FOUND)


class BmpReader extends FileTypeReader:
	func read_resolution(data: StreamPeerBuffer) -> Vector2i:
		var file_size = data.get_size()
		if file_size < 22:
			return Vector2i(-1, Errors.FILE_TOO_SMALL)
			
		data.big_endian = false 
		data.seek(0)
		
		# "BM"
		if data.get_u8() != 0x42 or data.get_u8() != 0x4D:
			return Vector2i(-1, Errors.INVALID_SIGNATURE)
			
		# jump to header
		data.seek(14)
		var dib_header_size = data.get_u32()
		
		var width: int = 0
		var height: int = 0
		
		if dib_header_size == 12: # BITMAPCOREHEADER
			width = data.get_u16()
			height = data.get_u16()
		elif dib_header_size >= 40: # BITMAPINFOHEADER / BITMAPVxHEADER
			# Width and height are 32-bit signed integers.
			# This is because Microsoft hates you.
			width = abs(data.get_32())
			height = abs(data.get_32())
		else:
			return Vector2i(-1, Errors.INVALID_CHUNK)
			
		return Vector2i(width, height)


static func get_reader(format: StringName) -> FileTypeReader:
	if format == &"jpeg":
		format = &"jpg"
	print(_readers)
	return _readers.get(format)
