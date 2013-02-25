GBJSON
======

Long story short:

I'm trying to create some kind of GSON parser for iOS 5.0 (and over)

Long story long:

As you probably know, since iOS 5.0 it's possible to serialize objects using JSON easily.
So it's quite simple to get a JSON NSData representation of an object using:

[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&jsonError];

Similarly it's possible to get a JSON object from it's NSData representation using:

[NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];

But the problem of this method is that it's matching each object using NSDictionary.
So this small code tries to get rid of this by using the result of JSONObjectWithData: as an input.
Then it tries to match dictionaries with given classes by using variables identifiers in JSON stream.
For example if you have a string in your JSON stream like:
"firstName": "John"
The program will try to find the variable firstName in the given class and if it finds it, it will set its value to "John"

It's quite easy to use this parser:

// Get your data
NSData *jsonData = ...;

// Get your JSON object
id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];

// Check jsonError and that jsonObject != nil
// Then call SPJSON
MyClass *myObject = [SPJSON parseJSONObject:jsonObject usingClass:[MyClass class] sender:self];

And it will log errors if there is a problem or it will just initialize all variables of MyClass that are in your JSON stream :)

At this moment the only big issue I had to overcome was that in Objective-C arrays are not strongly typed.
That's why in the .h file you will see a SPJSONProvider protocol. The aim of this protocol is to be implemented by a sender which knows the Class of the elements in the array currently parsed.
As JSON stream only gives you the identifier of the array, I'm using it to ask the Class using the following method:

- (Class)getClassForElementsInArrayNamed:(NSString *)arrayName;

So it's up to the sender to know the class of the elements for a given array name. Be careful, when you implement this method in your sender (if you have arrays to parse) you should return the right class when you know the array name, and nil otherwise.

For the moment it's still in experimental stage and I guess that some cases are not supported.
So just let me know if you have issues and I will try to find solutions ;)