//  gcodeToThumbnail.m
//
//  Created by David Phillip Oster on 2/4/23.
//

#import <AppKit/AppKit.h>

/// @return same aspect ratio as size, filling the longest dimension of the square rect.
NSRect RectOfSizeCenteredIn(CGSize size, NSRect rect) {
  NSRect r = rect;
  if (size.width < size.height) {
    r.size.width = size.width *  rect.size.height/size.height;
    r.origin.x += (rect.size.width - r.size.width)/2;
  } else {
    r.size.height = size.height * rect.size.width/size.width;
    r.origin.y += (rect.size.height - r.size.height)/2;
  }
  return r;
}

/// @return Resized image to the 512, 512 that macOS wants.
NSImage *ResizeImage(NSImage *img){
  if (nil == img || 0 == img.size.width || 0 == img.size.height) { return nil; }
  NSImage *newImage = [[NSImage alloc] initWithSize:CGSizeMake(512, 512)];
  [newImage lockFocus];
  [[NSColor clearColor] set];
  NSRectFill(NSMakeRect(0, 0, 512, 512));
  [img drawInRect:RectOfSizeCenteredIn(img.size, NSMakeRect(0, 0, 512, 512))];
  [newImage unlockFocus];
  return newImage;
}

/// @return first maxHead bytes as a C string in an NSData
NSData *HeadOfFile(const char *pathS){
  NSString *path = [NSFileManager.defaultManager stringWithFileSystemRepresentation:pathS length:strlen(pathS)];
  NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
  if (nil == fh){
    NSLog(@"couldn't open %s\n", pathS);
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

/// @return the base64 encoded thumbnail data (with leading semicolons on each line)
NSArray<NSData *> *ThumbnailBase64sFromData(NSData * data){
  if (data.length < 10) { return nil; }
  NSMutableArray<NSData *> *a = [NSMutableArray array];
  const char *start = data.bytes;
  while(YES){
    start = strstr(start, "; thumbnail begin");
    if (nil == start) {
      return a;
    }
    start = strstr(start, "\n");
    if (nil == start) { return nil; }
    start += 1; // skip that newline.
    const char *end = strstr(start, "; thumbnail end");
    if (nil == end) { return a; }
    [a addObject: [NSData dataWithBytes:start length:end - start]];
    start = end + 1;
  }
  return a;
}

/// @return Undone base64 encoding
NSArray<NSData *> *FromBase64s(NSArray<NSData *> *base64s){
  if (base64s.count < 1) { return nil; }
  NSMutableArray<NSData *> *a = [NSMutableArray array];
  for (NSData *base64 in base64s) {
    NSData *data = [[NSData alloc] initWithBase64EncodedData:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (data) {
      [a addObject:data];
    }
  }
  return a;
}

/// @return Convert to an NSImage. NSData is a .png or .jpg file in memory.
NSArray<NSImage *> *IconsFromData(NSArray<NSData *> *datas){
  NSMutableArray<NSImage *> *a = [NSMutableArray array];
  for (NSData *data in datas) {
    if (10 < data.length) {
      NSImage *img = [[NSImage alloc] initWithData:data];
      if (img) {
        [a addObject:img];
      }
    }
  }
  return a;
}

/// @return given an array of images, return the one with the largest pixels.
NSImage *LargestIcon(NSArray<NSImage *> *images){
  if (images.count < 1) { return nil; }
  NSImage *largestImage = images[0];
  for (NSImage *image in images) {
    if (largestImage.size.width * largestImage.size.height < image.size.width * image.size.height) {
      largestImage = image;
    }
  }
  return largestImage;
}

/// Attach the thumbnail to the file.
BOOL SetIcon(const char *pathS, NSImage *img){
  if (nil == img) { return NO; }
  BOOL isOK = [NSWorkspace.sharedWorkspace setIcon:img forFile:[NSString stringWithUTF8String:pathS]options:0];
  if (!isOK) {
    NSLog(@"couldn't attach thumbnail %s\n", pathS);
  }
  return isOK;
}

int GCodeToImageFile(const char *s){
  return SetIcon(s, ResizeImage(LargestIcon(IconsFromData(FromBase64s(ThumbnailBase64sFromData(HeadOfFile(s)))))));
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    if (1 < argc) {
      for (argv++;NULL != *argv;argv++) {
        if (!GCodeToImageFile(*argv)) {
        }
      }
    } else {
      NSLog(@"Usage: %s [ file.gcode ]\nby David Phillip Oster, Apache License\n", argv[0]);
    }
  }
  return 0;
}
