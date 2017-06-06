/* -*-objc-*-


   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: January 2003
   Author of Cappuccino port: Daniel Boehringer (2012)

   This file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

@import "GSMarkupTagControl.j"

@implementation GSMarkupTagTextField: GSMarkupTagControl
+ (CPString) tagName
{
  return @"textField";
}

+ (Class) platformObjectClass
{
  return [CPTextField class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  /* should be editable and selectable by default.  */

  /* editable */
  {
    var editable = [self boolValueForAttribute: @"editable"];
    
    if (editable == 0)
      {
	[platformObject setEditable: NO];
      }
    else
      {
	[platformObject setEditable: YES];	
      }
  }

  /* selectable */
  {
    var selectable = [self boolValueForAttribute: @"selectable"];
    
    if (selectable == 0)
      {
	[platformObject setSelectable: NO];
      }
    else
      {
	[platformObject setSelectable: YES];
      }
  }
  
  /* allowsEditingTextAttributes  */
  if( [platformObject respondsToSelector:@selector(setAllowsEditingTextAttributes:)])
  {
    var allowsEditingTextAttributes = [self boolValueForAttribute: @"allowsEditingTextAttributes"];

    if (allowsEditingTextAttributes == 1 )
      {
	[platformObject setAllowsEditingTextAttributes: YES];
      }
    else
      {
	[platformObject setAllowsEditingTextAttributes: NO];
      }
  }

  /* importsGraphics  */
  if( [platformObject respondsToSelector:@selector(setImportsGraphics:)])
  {
    var importsGraphics = [self boolValueForAttribute: @"importsGraphics"];

    if (importsGraphics == 1)
      {
	[platformObject setImportsGraphics: YES];
      }
    else
      {
	[platformObject setImportsGraphics: NO];
      }
  }

  /* placeholder */
  {
    var c = [self stringValueForAttribute: @"placeholder"];
    
    if (c != nil)
      {
	[platformObject setPlaceholderString: c];
      }
  }

  /* textColor */
  {
    var c = [self colorValueForAttribute: @"textColor"];
    
    if (c != nil)
      {
	[platformObject setTextColor: c];
      }
  }

  /* backgroundColor */
  {
    var c = [self colorValueForAttribute: @"backgroundColor"];
    
    if (c != nil)
      {
	[platformObject setBackgroundColor: c];
      }
  }

  /* drawsBackground */
  {
    var drawsBackground = [self boolValueForAttribute: @"drawsBackground"];

    if (drawsBackground == 1)
      {
	[platformObject setDrawsBackground: YES];
      }
    else if (drawsBackground == 0)
      {
	[platformObject setDrawsBackground: NO];
      }
  }

  /* eventual text is in the content.  */
  {
      {
	if (_content != nil)
	  {
	    [platformObject setStringValue: _content];
	  }
      }
  }
	[platformObject setBezeled:YES];

  return platformObject;
}

@end

var _GSComboBoxDSCompletionTest = function(object, index, context)
{
    return object.toString().toLowerCase().indexOf(context.toLowerCase()) === 0;
};

var _GSComboBoxHasName = function(object, index, context)
{
    return object == context;
};



@implementation _GSComboBoxDS: CPObject
{
    CPArray _items;
}

- (id)init
{
    if (self = [super init])
    {
        _items = [];
    }
    
    return self;
}

- (void)addItemWithTitle:(CPString)aTitle
{
    _items.push(aTitle);
}
- (CPInteger)numberOfItemsInComboBox:(CPComboBox)comboBox
{   return _items.length;
}
- (id)comboBox:(CPComboBox)comboBox objectValueForItemAtIndex:(CPInteger)index
{
    return _items[index];
}
- (CPUInteger)comboBox:(CPComboBox)comboBox indexOfItemWithStringValue:(CPString)string
{
    return _items.indexOf(string);
}
- (CPString)comboBox:(CPComboBox)comboBox completedString:(CPString)string
{
    var index = [_items indexOfObjectPassingTest:_GSComboBoxDSCompletionTest context:string];
    return index !== CPNotFound ? _items[index] : nil;

}

@end


@implementation GSMarkupTagComboBox: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"comboBox";
}

+ (Class) platformObjectClass
{
	return [CPComboBox class];
}

- (id) initPlatformObject: (id)platformObject
{
	platformObject = [super initPlatformObject:platformObject];

    if ([self boolValueForAttribute: @"completes"] == 1)
        [platformObject setCompletes:YES];

    var count = [_content count];
    if (count)
    {
        var myDS = [_GSComboBoxDS new];
        [platformObject setUsesDataSource:YES];
        [platformObject setDataSource:myDS];

        for (var i = 0; i < count; i++)
        {
            var title = [[_content objectAtIndex:i]._attributes objectForKey: @"title"];

            if (!title)
                title = @"";
            
            [myDS addItemWithTitle:title];
        }
        [platformObject setObjectValue:""]
    }
    return platformObject;
}

@end

@implementation GSMarkupTagComboBoxTagValue: GSMarkupTagComboBox
+ (CPString) tagName
{
    return @"comboBox";
}

+ (Class) platformObjectClass
{
    return [GSComboBoxTagValue class];
}

@end

@implementation _CPComboTagContentBinder : _CPComboBoxContentBinder

- (void)setValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey];
    var options = [_info objectForKey:CPOptionsKey];
    var myvalkey = [options objectForKey:"valueFace"];
    _source._realObjectValues = [destination valueForKeyPath:"arrangedObjects."+myvalkey];
    [super setValueFor:aBinding];
}
@end

@implementation _CPComboTagValueBinder : CPBinder

// name->id
- (id)reverseTransformValue:(id)newValue withOptions:(id)options
{
    var index = [_source._items indexOfObjectPassingTest:_GSComboBoxHasName context:newValue];
    return index !== CPNotFound ? _source._realObjectValues[index] : nil;
}
// id->name
- (id)transformValue:(id)newValue withOptions:(id)options
{
    var index = [_source._realObjectValues indexOfObjectPassingTest:_GSComboBoxHasName context:newValue];
    return index !== CPNotFound ? _source._items[index] : nil;
}

@end

@implementation GSComboBoxTagValue : CPComboBox
{
    CPArray _realObjectValues;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPContentBinding || aBinding === CPContentValuesBinding)
        return [_CPComboTagContentBinder class];

    if (aBinding === CPValueBinding)
        return [_CPComboTagValueBinder class];
    
    return [super _binderClassForBinding:aBinding];
}

@end

@implementation GSMarkupTagSearchField: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"searchField";
}

+ (Class) platformObjectClass
{
	return [CPSearchField class];
}

- (id) initPlatformObject: (id)platformObject
{
	platformObject = [super initPlatformObject: platformObject];
  /* autosaveName */
    var autosaveName = [_attributes objectForKey: @"autosaveName"];
    if (autosaveName != nil) [platformObject setRecentsAutosaveName: autosaveName];

	return platformObject;
}
- (id) postInitPlatformObject: (id)platformObject
{
	platformObject = [super postInitPlatformObject: platformObject];
	[platformObject _init];
	return platformObject;
}

@end


@implementation GSMarkupTagSecureTextField: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"secureField";
}

+ (Class) platformObjectClass
{
	return [CPSecureTextField class];
}

@end
