
@import <Foundation/CPObject.j>
@import <Foundation/CPMutableArray.j>

@implementation CPArray (KeyValueObservingFix)
- (void)addObserver:(id)anObserver forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)anOptions context:(id)aContext
{	// do not raise because we know...
}
- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aKeyPath
{	// do not raise because we know...
}

@end

@implementation FSMutableArray : CPMutableArray
{	id _entity @accessors(property=entity);
    id _proxyObject;
	id _defaults @accessors(property=defaults);

	id _kvoKey @accessors(property=kvoKey);
	id _kvoOwner @accessors(property=kvoOwner);
    id _kvoMethod;
}

+ (id)alloc
{
    var array = [];

    array.isa = self;

    var ivars = class_copyIvarList(self),
        count = ivars.length;

    while (count--)
        array[ivar_getName(ivars[count])] = nil;

    return array;
}

- (id)initWithArray:(id)anObject ofEntity:(id)someEntity
{	self = [super init];

    _proxyObject = anObject;
	_entity=someEntity;
    return self;
}

- (id)copy
{	var i = 0,
        theCopy = [],
        count = [self count];

    for (; i < count; i++)
        [theCopy addObject:[self objectAtIndex:i]];

    return theCopy;
}

- (id)_representedObject
{
    return _proxyObject;
}

- (void)_setRepresentedObject:(id)anObject
{

    [_proxyObject setArray: anObject];
}

- (unsigned)count
{	return [[self _representedObject] count];
}

- (int)indexOfObject:(CPObject)anObject inRange:(CPRange)aRange
{
    var index = aRange.location,
        count = aRange.length,
        shouldIsEqual = !!anObject.isa;

    for (; index < count; ++index)
    {
        var object = [self objectAtIndex:index];

        if (anObject === object || shouldIsEqual && !!object.isa && [anObject isEqual:object])
            return index;
    }

    return CPNotFound;
}

- (int)indexOfObject:(CPObject)anObject
{
    return [self indexOfObject:anObject inRange:CPMakeRange(0, [self count])];
}

- (int)indexOfObjectIdenticalTo:(CPObject)anObject inRange:(CPRange)aRange
{
    var index = aRange.location,
        count = aRange.length;

    for (; index < count; ++index)
        if (anObject === [self objectAtIndex:index])
            return index;

    return CPNotFound;
}

- (int)indexOfObjectIdenticalTo:(CPObject)anObject
{
    return [self indexOfObjectIdenticalTo:anObject inRange:CPMakeRange(0, [self count])];
}

- (id)objectAtIndex:(unsigned)anIndex
{
    return [[self objectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]] firstObject];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)theIndexes
{	return [[self _representedObject] objectsAtIndexes:theIndexes];
}

- (FSObject) _addToDBObject: anObject
{
	if(_defaults)
	{	if([anObject isKindOfClass: [CPDictionary class]])
		{	[anObject addEntriesFromDictionary: _defaults];
		} else if( [anObject isKindOfClass: [FSObject class] ] )
		{	if(!anObject._changes) anObject._changes = [CPMutableDictionary dictionary];
			[anObject._changes addEntriesFromDictionary: _defaults];
		}
	}
	return [_entity insertObject: anObject];
}

- (void)addObject:(id)anObject
{
    [self insertObject:anObject atIndex:[self count]];
}

- (void)addObjectsFromArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    [self insertObjects:anArray atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange([self count], count)]];
}

- (void)insertObject:(id)anObject atIndex:(unsigned)anIndex
{
    [self insertObjects:[anObject] atIndexes:[CPIndexSet indexSetWithIndex:anIndex]];
}

- (void)insertObjects:(CPArray)theObjects atIndexes:(CPIndexSet)theIndexes
{	var target = [[self _representedObject] copy];
	var myarr=[];
	var l=[theObjects count];
	for(var i=0; i<l; i++)
	{	var o=[theObjects objectAtIndex: i ];
		if(_entity) o= [self _addToDBObject: o ];
		[myarr addObject: o];
	}
	[target insertObjects: myarr atIndexes:theIndexes];
	[self _setRepresentedObject:target];
}

- (void)removeObject:(id)anObject
{	[self removeObject:anObject inRange:CPMakeRange(0, [self count])];
}

- (void)removeObjectsInArray:(CPArray)theObjects
{
	var l=[theObjects count];
	for(var i=0; i<l; i++)
	{	[_entity deleteObject: [theObjects objectAtIndex: i ] ];
	}

	var target = [[self _representedObject] copy];
	[target removeObjectsInArray:theObjects];
	[self _setRepresentedObject:target];
}

- (void)removeObject:(id)theObject inRange:(CPRange)theRange
{	var index;

	while ((index = [self indexOfObject:theObject inRange:theRange]) !== CPNotFound)
	{	[_entity deleteObject: [self objectAtIndex: index ] ];

		[self removeObjectAtIndex:index];
		theRange = CPIntersectionRange(CPMakeRange(index, length - index), theRange);
	}
}

- (void)removeLastObject
{
    [self removeObjectsAtIndexes:[CPIndexSet indexSetWithIndex:[self count] - 1]];
}

- (void)removeObjectAtIndex:(unsigned)anIndex
{
    [self removeObjectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]];
}

- (void)removeObjectsAtIndexes:(CPIndexSet)theIndexes
{	var target = [[self _representedObject] copy];
	var theObjects=[[self _representedObject] objectsAtIndexes: theIndexes ];
	var l=[theObjects count];
	for(var i=0; i<l; i++)
	{	[_entity deleteObject: [theObjects objectAtIndex: i ] ];
	}
	[target removeObjectsAtIndexes:theIndexes];
	[self _setRepresentedObject:target];
}

- (void)replaceObjectAtIndex:(unsigned)anIndex withObject:(id)anObject
{
    [self replaceObjectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex] withObjects:[anObject]]
}

- (void)replaceObjectsAtIndexes:(CPIndexSet)theIndexes withObjects:(CPArray)theObjects
{	var target = [[self _representedObject] copy];
	[target replaceObjectsAtIndexes:theIndexes withObjects:theObjects];
	[self _setRepresentedObject:target];
}

-(CPString) description
{	return [[self _representedObject] description];
}

- (void)sortUsingFunction:(Function)aFunction context:(id)aContext
{	var target = [[self _representedObject] copy];
	[target sortUsingFunction:aFunction context:aContext];
	[self _setRepresentedObject:target];
}

-(void) connection:(CPConnection)someConnection didReceiveData:(id)data
{	var j = JSON.parse(data);
	var a = [];
	if(j)
	{	var i,l=j.length;
		for(i=0;i < l;i++)
		{	var pk=j[i][_entity._pk];
			var peek;
			if (peek=[_entity _registeredObjectForPK:pk])	// enforce singleton pattern
				a.push(peek);
			else
			{	var t=[[FSObject alloc] initWithEntity:_entity];
                var o=j[i];
                t._data = [CPMutableDictionary dictionary];
                for (var propName in o) {
                    if (o.hasOwnProperty(propName)) {
                        var pnv = o[propName];
                        if(pnv !== nil)
                            t._data.setValueForKey(propName, pnv);
                    }
                }
				[_entity _registerObjectInPKCache:t];
                a.push(t);
			}
		}
	}
	if(_kvoKey&& _kvoOwner)
		[_kvoOwner willChangeValueForKey: _kvoKey];

	[self _setRepresentedObject:a];

	if(_kvoKey && _kvoOwner)
        [_kvoOwner didChangeValueForKey: _kvoKey];

    if(_kvoMethod && _kvoOwner)
        [_kvoOwner performSelector:_kvoMethod withObject:self];

	if(_entity.__ACForSpinner && _entity.__ACForSpinner.__tableViewForSpinner)
		[_entity.__ACForSpinner.__tableViewForSpinner _stopAnimation: self];
}

@end
