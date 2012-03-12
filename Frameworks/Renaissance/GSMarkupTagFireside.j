
@import "GSMarkupTagObject.j"
@import <Foundation/CPObject.j>
@import "Fireside.j"

@implementation GSMarkupColumn: GSMarkupTagObject
+ (CPString) tagName
{
  return @"column";
}

@end


@implementation GSMarkupEntity: GSMarkupTagObject
+ (CPString) tagName
{
  return @"entity";
}

+ (Class) platformObjectClass
{
  return [FSEntity class];
}

- (id) initPlatformObject: (id)platformObject
{	var store = [_attributes objectForKey: @"store"];
	var name = [_attributes objectForKey: @"name"];
//alert(name);
	platformObject = [platformObject initWithName: name andStore: store ];
//alert([self description]);
//alert([_content description]);

// now extract columns..
    var i, count = _content.length;
	for (i = 0 ; i < count; i++)
	{	var v = _content[i];
//alert([v description]);
	}

	return platformObject;
}

@end
