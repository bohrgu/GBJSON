GBJSON
======

This code provides a way to parse a deserialized JSON object and to match it with Objective-C classes.

Who Can Use It
----------

OSX and iOS developpers who are using ARC (so over iOS 5.0).

Description
----------

### Long story short

I'm trying to create some kind of GSON (Android) parser for iOS 5.0 (and over)

### Long story long

As you probably know, since iOS 5.0 it's possible to serialize objects using JSON easily.
So it's quite simple to get a JSON NSData representation of an object using:

```objective-c
[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&jsonError];
```

Similarly it's possible to get a JSON object from it's NSData representation using:

```objective-c
[NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
```

But the problem of this last method is that it's matching all objects using NSDictionary.
So GBJSON tries to get rid of this by using the result of JSONObjectWithData: as an input.
Then it tries to match dictionaries with given classes by using variables identifiers in JSON stream.

For example if you have a string in your JSON stream like:
"firstName": "John"

The program will try to find the variable firstName in a given class and if it finds it, it will set its value to "John".

How To Use
----------

### Initial steps

It's quite easy to use this parser. You need to deserialize your JSON stream first and then you need to call GBJSON with 3 things:

- The JSON object you deserialized
- The Class of the first object (could be an NSArray)
- A provider (discribed in "Provider implementation")

```objective-c
#import "GBJSON.h"

...

{

	...

	// Get your data
	NSData *jsonData = ...;

	// Get your JSON object
	id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];

	// Check jsonError and that jsonObject != nil

	// Then call GBJSON
	MyClass *myObject = [GBJSON parseJSONObject:jsonObject usingClass:[MyClass class] provider:self];

	...

}
```

It will log errors if there are problems or it will just initialize all variables of MyClass that are in your JSON stream.

### Provider implementation

There are 3 issues to fully parse a deserialized JSON:

- 1- Objective-C arrays are not strongly typed
- 2- JSON stream may contain string values for non-string object (e.g. NSDate)
- 3- JSON stream may contain string values for scalar variables or enums

That's why in GBJSON.h there is a GBJSONProvider protocol with the 3 following functions:

- (Class)getClassForElementsInArrayNamed:(NSString *)arrayName;
- (id)getObjectForClass:(Class)aClass fromString:(NSString *)aString;
- (NSNumber*)getNSNumberForString:(NSString *)aString;

A small example will be perfect to explain how to implement these functions.
Imagine that a webservice is giving you the following JSON.

```json
{
	"name":"Robert Allen Zimmerman",
	"number":"+353600000000",
	"birthDate":"19410524000000",
	"gender":"male",
	"hasFans":"true",
	"contacts":[
	{
		"name":"Bob",
		"number":"+353600000000"
	},
	{
		"name":"Dylan",
		"number":"+33699999999"
	}
	]
}
```

And that you want to parse this JSON to fit with the following class.

```objective-c
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GenderType)
{
    GenderTypeMale,
    GenderTypeFemale,
    GenderTypeOther
};

@interface Person : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) NSDate *birthDate;
@property (assign, nonatomic) GenderType gender;
@property (assign, nonatomic) BOOL hasFans;
@property (strong, nonatomic) NSArray *contacts;

@end
```

The first problem you will face will be the "birthDate" because it's a string in the JSON. To solve this issue GBJSON will call the function getObjectForClass:fromString:
So your provider should implement it like the following.

```objective-c
- (id)getObjectForClass:(Class)aClass fromString:(NSString *)aString
{
	if (aClass == [NSDate class])
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		return [dateFormatter dateFromString:aString];
	}

	// Don't forget to return nil by default
	return nil;
}
```

Then you will have issues with "gender" and "hasFans" variables. getNSNumberForString: will help you to get rid of these two.
Implement the following in your provider.

```objective-c
- (NSNumber*)getNSNumberForString:(NSString *)aString
{
	if ([aString isEqualToString:@"true"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([aString isEqualToString:@"false"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([aString isEqualToString:@"male"])
	{
		return [NSNumber numberWithInteger:GenderTypeMale];
	}
	else if ([aString isEqualToString:@"female"])
	{
		return [NSNumber numberWithInteger:GenderTypeFemale];
	}
	else if ([aString isEqualToString:@"other"])
	{
		return [NSNumber numberWithInteger:GenderTypeOther];
	}

	// Don't forget to return nil by default
	return nil;
}
```

Finally you will have an issue with "contacts" because in Objective-C arrays are not strongly-typed. So it's hard for the parser to know the type of objects inside an array.
But the provider should have this information. That's why GBJSON will ask the provider to getClassForElementsInArrayNamed:.
So implement the following in your provider.

```objective-c
- (Class)getClassForElementsInArrayNamed:(NSString *)arrayName
{
	if ([arrayName isEqualToString:@"contacts"])
	{
		return [Person class];
	}

	// Don't forget to return nil by default
	return nil;
}
```

For the moment it's still in experimental stage and I guess that some cases are not supported (like NSDictionary inside Objective-C objects).
So just let me know if you have issues and I will try to find solutions ;)

Future Enhancements
-------------------

- Allow users to use NSDictionary variables.

Licenses
--------

The source code is licensed under the [Apache License V2.0](http://www.apache.org/licenses/LICENSE-2.0).