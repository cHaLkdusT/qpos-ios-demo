//
//  Util.h
//  qpossdk
//
//  Created by wangxu on 13-11-5.
//  Copyright (c) 2013年 xiaochengdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+(NSString*)byteArray2Hex: (NSData *)data;
+(NSData *)HexStringToByteArray: (NSString*)hexString;
+(NSString*)getHexString: (NSData *)b;
+(NSData *)IntToHex: (NSInteger)i;
+(void)printHexString: (NSData *)b;
+(NSInteger)byteArrayToInt: (NSData *)data;
+(Byte)XorByteStream: (Byte *)b SteamStartOffset:(NSInteger)startPos StreamLen:(NSInteger)Len;
+(NSData *)get: (Byte *)array ArrayOffset:(NSInteger)offset;
+(NSData *)get: (Byte *)array ArrayOffset:(NSInteger)offset ToGetLength:(NSInteger)length;
+(void)turnUpVolume: (NSInteger)factor;
+(NSString *)asciiFormatString:(NSData *)adata;
+(NSData *)stringFormatTAscii:(NSString *)aString;
+(BOOL)isPureInt:(NSString*)string;
+(BOOL)isPureFloat:(NSString*)string;
+(NSString *)gbString:(NSString *)string;
+(NSData *)restructureBMP:(NSString *)origin width:(int)width height:(int)height;
+(NSDictionary *)anlysData:(NSString *)tlv;
+(NSData *)ecb:(NSData *)aData;
+(NSData *)bcd2asc:(NSData*)aData;
@end
