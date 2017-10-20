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

@import <AppKit/CPTableView.j>
@import "GSMarkupTagControl.j"


@implementation FSTableView: CPTableView

- (void)_commitDataViewObjectValue:(id)sender
{	[self _commitDataViewObjectValue:sender forColumn:_editingColumn andRow:_editingRow];
}

-(void) _startAnimation:sender
{	if(!self._spinner)
	{	var progres=[CPProgressIndicator new];
		[progres setStyle:CPProgressIndicatorSpinningStyle];
		[progres setIndeterminate:YES];
		var frame=[_superview frame];
		frame.origin.x=frame.size.width/2-32;
		frame.origin.y=frame.size.height/2;
		frame.size.width=64;
		frame.size.height=64;
		[progres setFrame: frame];
		[self addSubview: progres];
		self._spinner=progres;
		[progres startAnimation:self];
	}
}
-(void) _stopAnimation:sender
{	var progres=self._spinner;
	if(progres)
	{	[progres stopAnimation:self];
		[progres removeFromSuperview];
		self._spinner=nil;
	}
}

-(void) sizeToFit
{
}

-(void) undo:sender
{
   var binder=[CPBinder getBinding:"content" forObject:self];
   var ac=[binder._info objectForKey:CPObservedObjectKey]
   [ac undo];
}

-(void) redo:sender
{
   var binder=[CPBinder getBinding:"content" forObject:self];
   var ac=[binder._info objectForKey:CPObservedObjectKey]
   [ac redo];
}

-(unsigned) findColumnWithTitle:(CPString) aTitle
{   var l=[_tableColumns count];
    for(var i=0;i<l;i++)
    {   if(_tableColumns[i]._identifier === aTitle)
            return i;
    }
    return -1;
}
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    var character = [anEvent charactersIgnoringModifiers],
        modifierFlags = [anEvent modifierFlags];

    if ( [anEvent keyCode] == CPTabKeyCode && self._currentFirstResponder)
    {
        var selectedColumn=[self columnForView:self._currentFirstResponder] + 1;
        if (selectedColumn > 0 && selectedColumn < [self numberOfColumns] && [[_tableColumns objectAtIndex:selectedColumn] isEditable] && (!_delegate || [_delegate tableView:self shouldEditTableColumn:selectedColumn row:[self selectedRow]]))
        {   [self editColumn:selectedColumn row:[self selectedRow] withEvent:anEvent select:YES]
        }
        return YES;
    }
    return [super performKeyEquivalent:anEvent];
}

- (void)_init
{
    [super _init];

    var handlekeydown=function(e){
        if (e.keyCode == 9)
        {
            self._currentFirstResponder=[_window firstResponder];
           [_window makeFirstResponder:self];
        }
    }

    self._DOMElement.addEventListener('keydown',handlekeydown,NO);
}

@end

@implementation GSMarkupTagTableView: GSMarkupTagControl


+ (CPString) tagName
{
  return @"tableView";
}

+ (Class) platformObjectClass
{
  return [FSTableView class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  /* dataSource and delegate are outlets.  */

  /* doubleAction */
  {
    var doubleAction = [_attributes objectForKey: @"doubleAction"];
  
    if (doubleAction != nil)
      {
	[platformObject 
			setDoubleAction: CPSelectorFromString (doubleAction)];
      }
  }  

  /* allowsColumnReordering */
  {
    var value = [self boolValueForAttribute: @"allowsColumnReordering"];

    if (value == 1)
      {
	[platformObject setAllowsColumnReordering: YES];
      }
    else if (value == 0)
      {
	[platformObject setAllowsColumnReordering: NO];
      }
  }

  /* hide selection */
  {
    var value = [self boolValueForAttribute: @"hideSelection"];

    if (value == 1)
      {
	[platformObject setSelectionHighlightStyle: CPTableViewSelectionHighlightStyleNone];
      }
  }


  /* allowsColumnResizing */
  {
    var value = [self boolValueForAttribute: @"allowsColumnResizing"];

    if (value == 1)
      {
	[platformObject setAllowsColumnResizing: YES];
      }
    else if (value == 0)
      {
	[platformObject setAllowsColumnResizing: NO];
      }
  }

  /* allowsMultipleSelection */
  {
    var value = [self boolValueForAttribute: @"allowsMultipleSelection"];

    if (value == 1)
      {
	[platformObject setAllowsMultipleSelection: YES];
      }
    else if (value == 0)
      {
	[platformObject setAllowsMultipleSelection: NO];
      }
  }

  /* allowsEmptySelection */
  {
    var value = [self boolValueForAttribute: @"allowsEmptySelection"];

    if (value == 1)
      {
	[platformObject setAllowsEmptySelection: YES];
      }
    else if (value == 0)
      {
	[platformObject setAllowsEmptySelection: NO];
      }
  }
  {
    var value = [self boolValueForAttribute: @"usesAlternatingRowBackgroundColors"] || [self boolValueForAttribute: @"zebra"];

    if (value == 1)
      {
	[platformObject setUsesAlternatingRowBackgroundColors:YES];
      }
  }

  /* allowsColumnSelection */
  {
    var value = [self boolValueForAttribute: @"allowsColumnSelection"];

    if (value == 1)
      {
	[platformObject setAllowsColumnSelection: YES];
      }
    else if (value == 0)
      {
	[platformObject setAllowsColumnSelection: NO];
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

  /* drawsGrid */
  {
    var value = [self boolValueForAttribute: @"drawsGrid"];

    if (value == 1)
      {
	[platformObject setDrawsGrid: YES];
      }
    else if (value == 0)
      {
	[platformObject setDrawsGrid: NO];
      }
  }

  /* gridColor */
  {
    var c = [self colorValueForAttribute: @"gridColor"];
    if (c != nil)
      {
	[platformObject setGridColor: c];
      }
  }

    /* rowHeight */
    {
        var value = [self intValueForAttribute: @"rowHeight"];

        if (value)
        {
            [platformObject setRowHeight:value];
        }
    }

  /* Now the contents.  An array of tableColumn objects.  */
  {
    var i, numberOfColumns;
    numberOfColumns = [_content count];
    for (i = 0; i < numberOfColumns; i++)
      {
	var column = [_content objectAtIndex: i];
	
	if (column != nil 
	    && [column isKindOfClass: [GSMarkupTagTableColumn class]])
	  {
	    [platformObject addTableColumn: 
			      [column platformObject]];
	  }
      }
  }

  return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{
// causes some weired sizing issues in capp...
  // platformObject = [super postInitPlatformObject: platformObject];

  /* Adjust columns/table to fit.  */
  [platformObject sizeToFit];  

  /* autosaveName */
  {
    var autosaveName = [_attributes objectForKey: @"autosaveName"];
    if (autosaveName != nil)
      {
	/* Please note that setting the autosaveName should also read
	 * the saved columns' ordering and width (and the table's
	 * one!).  This is why we do this after all columns have been
	 * loaded, and after we've called sizeToFit.  */
	[platformObject setAutosaveName: autosaveName];

	/* If an autosaveName is set, automatically turn on using it!  */
	[platformObject setAutosaveTableColumns: YES];
      }
  }  

  return platformObject;
}

@end

@implementation CPObject(FSSortDescriptorAddition)
- (CPComparisonResult)compareNumericallyTo: rhsObject 
{	if (parseInt(self) < parseInt(rhsObject)) return CPOrderedAscending;
	if (parseInt(self) > parseInt(rhsObject)) return CPOrderedDescending;
	return CPOrderedSame;
}
@end

@implementation GSMarkupTagSortDescriptor : GSMarkupTagObject
+ (CPString) tagName
{	return @"sortDescriptor";
}

+ (Class) platformObjectClass
{	return nil;
}

- (id) initPlatformObject: (id)platformObject
{	platformObject=[CPSortDescriptor sortDescriptorWithKey: [self stringValueForAttribute:"key"] ascending: [self boolValueForAttribute:"ascending"]!=0 ];
	if([self boolValueForAttribute:"numeric"]==1) platformObject._selector= @selector(compareNumericallyTo:);
	return platformObject;
}
@end
