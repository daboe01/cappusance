
@import "GSMarkupTagObject.j"
@import <Foundation/CPObject.j>
@import "Fireside.j"

@implementation GSMarkupColumn: GSMarkupTagObject

var entityNameTable;
+(CPDictionary) entityNameTable
{
}
+ (CPString) tagName
{
  return @"column";
}
-(CPString) name
{	return [_attributes objectForKey: @"name"];
}
-(BOOL) isPK
{	return [self boolValueForAttribute: @"primaryKey"]==1;
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
@end

@implementation GSMarkupRelationship: GSMarkupTagObject
+ (CPString) tagName
{
  return @"relationship";
}
-(CPString) name
{	return [_attributes objectForKey: @"name"];
}
-(CPString) target
{	return [_attributes objectForKey: @"target"];
}
-(CPString) targetColumn
{	return [_attributes objectForKey: @"targetColumn"];
}
-(CPString) bindingColumn
{	return [_attributes objectForKey: @"bindingColumn"];
}
-(BOOL) isToMany
{	return [_attributes objectForKey: @"type"]=="toMany";
}

+ (Class) platformObjectClass
{	return [FSRelationship class];
}
@end


@implementation GSMarkupEntity: GSMarkupTagObject
+ (CPString) tagName
{
  return @"entity";
}

+ (Class) platformObjectClass
{	return [FSEntity class];
}

- (id) initPlatformObject: (id)platformObject
{	var store = [_attributes objectForKey: @"store"];

	var name = [_attributes objectForKey: @"id"];
	platformObject = [platformObject initWithName: name andStore: store ];

// now extract columns and PK...
	var myCols=[CPMutableSet new];

	var myPK;
    var i, count = _content.length;
	for (i = 0 ; i < count; i++)
	{	var v = _content[i];
		if([v isKindOfClass: [GSMarkupColumn class] ])
		{	if([v isPK])
			{	if(myPK) [CPException raise:CPInvalidArgumentException reason:@"Duplicate PK "+[v name]+"! "+ myPK+" already is PK!"];
				else myPK=[v name];
			}
			[myCols addObject: [v name]];
		} else if([v isKindOfClass: [GSMarkupRelationship class] ])
		{	var rel=[[FSRelationship alloc] initWithName: [v name] andTargetEntity: [v target]];	//set name as a temorary symbolic link. will be resolved in decoder later on.
			if([v bindingColumn]) [rel setBindingColumn: [v bindingColumn] ];
			if([v targetColumn]) [rel setTargetColumn: [v targetColumn] ];
			if([v isToMany]) [rel  setType: FSRelationshipTypeToMany];
			else [rel setType: FSRelationshipTypeToOne];
			[platformObject addRelationship: rel];
		}
	}
	[platformObject setColumns:myCols];
	if(myPK) [platformObject setPk: myPK];
	return platformObject;
}

@end

@implementation GSMarkupArrayController: GSMarkupTagObject
+ (CPString) tagName
{	return @"arrayController";
}

+ (Class) platformObjectClass
{	return [CPArrayController class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [platformObject init];
	return platformObject;
}

@end
