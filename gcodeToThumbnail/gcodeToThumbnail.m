//  gcodeToThumbnail.m
//
//  Created by David Phillip Oster on 2/4/23.
//

#import <AppKit/AppKit.h>

/// Resize image to the 512, 512 that macOS wants.
NSImage *ResizeImage(NSImage *img){
  if (nil == img) { return nil; }
  NSImage *newImage = [[NSImage alloc] initWithSize:CGSizeMake(512, 512)];
  [newImage lockFocus];
  [[NSColor clearColor] set];
  NSRectFill(NSMakeRect(0, 0, 512, 512));
  // TODO dest rect should have same aspect ratio as img.size, but 512 in longest dimension and centered in 0,0,512,512
  [img drawInRect:NSMakeRect(0, 0, 512, 512)];
  [newImage unlockFocus];
  return newImage;
}

/// Return first maxHead bytes as a C string in an NSData
NSData *HeadOfFile(const char *pathS){
  NSString *path = [NSFileManager.defaultManager stringWithFileSystemRepresentation:pathS length:strlen(pathS)];
  NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
  if (nil == fh){
    fprintf(stderr, "couldn't open %s\n", pathS);
    return nil;
  }
  unsigned long long length = [fh seekToEndOfFile];
  if (length < 100){ return nil; }
  static const NSInteger maxHead = 200000;
  [fh seekToFileOffset:0];
  NSMutableData *d = [[fh readDataOfLength:MIN(length, maxHead)] mutableCopy];
  if (d) {  // to use C string functions, must null terminate.
    NSInteger zero = 0;
    [d appendBytes:&zero length:1];
  }
  return d;
}

/// Return the base64 encoded thumbnail data (with leading semicolons on each line)
NSData *ThumbnailBase64FromData(NSData * data, const char *pathS){
  if (data.length < 10) { return nil; }
  const char *start = strstr(data.bytes, "; thumbnail begin");
  if (nil == start) {
    fprintf(stderr, "thumbnail not found %s\n", pathS);
    return nil;
  }
  start = strstr(start, "\n");
  if (nil == start) { return nil; }
  start += 1; // skip that newline.
  const char *end = strstr(start, "; thumbnail end");
  if (nil == end) { return nil; }
  return [NSData dataWithBytes:start length:end - start];
}

/// Undo the base64 encoding
NSData *FromBase64(NSData * base64, const char *pathS){
  if (base64.length < 10) { return nil; }
  NSData *data = [[NSData alloc] initWithBase64EncodedData:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
  if (nil == data) {
    fprintf(stderr, "couldn't decode thumbnail %s\n", pathS);
  }
  return data;
}

/// Convert to an NSImage. NSData is a .png or .jpg file in memory.
NSImage *IconFromData(NSData *data){
  if (data.length < 10) { return nil; }
  return [[NSImage alloc] initWithData:data];
}

/// Attach the thumbnail to the file.
BOOL SetIcon(NSImage *img, const char *pathS){
  if (nil == img) { return NO; }
  BOOL isOK = [NSWorkspace.sharedWorkspace setIcon:img forFile:[NSString stringWithUTF8String:pathS]options:0];
  if (!isOK) {
    fprintf(stderr, "couldn't attach thumbnail %s\n", pathS);
  }
  return isOK;
}

int GCodeToImageFile(const char *s){
  return SetIcon(ResizeImage(IconFromData(FromBase64(ThumbnailBase64FromData(HeadOfFile(s), s), s))), s);
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    if (1 < argc) {
      for (argv++;NULL != *argv;argv++) {
        if (!GCodeToImageFile(*argv)) {
        }
      }
    } else {
      fprintf(stderr, "Usage: %s [ file.gcode ]\nby David Phillip Oster, Apache License\n", argv[0]);
    }
  }
  return 0;
}
