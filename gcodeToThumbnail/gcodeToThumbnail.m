//  gcodeToThumbnail.m
//
//  Created by David Phillip Oster on 2/3/23.
//

#import <AppKit/AppKit.h>

NSImage *ResizeImage(NSImage *img){
  NSImage *newImage = [[NSImage alloc] initWithSize:CGSizeMake(512, 512)];
  [newImage lockFocus];
  [[NSColor clearColor] set];
  NSRectFill(NSMakeRect(0, 0, 512, 512));
  [img drawInRect:NSMakeRect(0, 0, 512, 512)];
  [newImage unlockFocus];
  return newImage;
}

int GCodeToImageFile(const char *s){
  if (NULL == freopen(s, "r", stdin)) {
    fprintf(stderr, "couldn't open %s\n", s);
    return 1;
  }

  char buffer[512];
  const char *startflag = "; thumbnail begin";
  NSInteger startLen = strlen(startflag);
  BOOL foundThumbnailEnd = NO;
  while(fgets(buffer, sizeof buffer - 1, stdin)) {
    // skip lines until we get to start of thumbnail.
    if (0 == strncmp(buffer, startflag, startLen)) {
      NSMutableData *base64 = [NSMutableData data];
      while (fgets(buffer, sizeof buffer - 1, stdin)) {
        if (0 == strcmp(buffer, "; thumbnail end\n")) {
          foundThumbnailEnd = YES;
          break;
        }
        [base64 appendBytes:buffer length:strlen(buffer)];
      }
      if (!foundThumbnailEnd) {
        fprintf(stderr, "thumbnail not found %s\n", s);
        return 1;
      }
      if (base64.length) {
        NSData *data = [[NSData alloc] initWithBase64EncodedData:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (10 < data.length) {
          NSImage *img = [[NSImage alloc] initWithData:data];
          if (img) {
            if (!(img.size.width == 512 && img.size.height == 512)) {
              img = ResizeImage(img);
            }
            NSWorkspace *ws = [NSWorkspace sharedWorkspace];
            if (nil == img || ![ws setIcon:img forFile:[NSString stringWithUTF8String:s]options:0]) {
              fprintf(stderr, "couldn't attach thumbnail %s\n", s);
              return 1;
            }
            return 0;
          }
        }
      }
      fprintf(stderr, "couldn't decode thumbnail %s\n", s);
      return 1;
    }
  }
  fprintf(stderr, "thumbnail not found %s\n", s);
  return 1;
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
