Cappusance is a powerful GUI builder for Cappuccino. 
Cappusance i.e. features strong autolayout capabilities. Cappusance is actually a port of GNUstep Renaissance.
See <http://www.gnustep.it/Renaissance/> for the original GNUstep Renaissance documentation. On top of that, Cappusance adds support for the more recent Cocoa controls and Cocoa bindings.

As a big plus, Cappusance comes with a RESTful Object/Relational Mapper (ORM). This allows you to write a CRUD-functional application in XML -- without writing code in Objective-J! The Cappusance ORM conveys automatic database-to-GUI mapping in the spirit of EOF/WebObjects: database entities map to ArrayControllers, relations can be expressed as master-detail bindings between ArrayControllers. Additionally, data manipulations from Objective-J are transparently forwarded to the backend. ArrayControllers are extended to support CPUndoManager's undo/redo out of the box.

Example usage with backend:
```Objective-J
@import <Renaissance/Renaissance.j>
[...]
- (void) applicationDidFinishLaunching:(CPNotification)aNotification
{
// _store is an instance variable with an accessor named store
	_store=[[FSStore alloc] initWithBaseURL: "http://127.0.0.1:3000"]; 
// gui.gsmarkup is loaded from the Ressources folder
// we specify "self" (our AppController instance) as 'files owner'.
// this object is aliased as '#CPOwner' in the markup file.
// You can access e.g. the store instance varibale via '#CPOwner.store' in your markup file.

	[CPBundle loadRessourceNamed: "gui.gsmarkup" owner:self];
// The gui markup will usually connect GUI objects to instance variables.
// From here on, manipulations at ArrayController and even at Objective-J level
// (e.g. insertion into Arrays) are magically mapped to the backend.
}
```
Mojolicious is a perfect match for creating backends (http://mojolicio.us/).
This modern perl framework comes with a powerful rest router and a builtin static server for serving the Cappuccino framework.
The REST dialect of Cappusance can be easily adapted to any backend. Ideally, you only need to subclass FSStore and override a few simple methods.

Unfortunately, i did not yet have the time to write documentation for the ORM-part (i.e. Fireside.j) and how everything fits together. However, a comprehensive use case is here:
<https://github.com/daboe01/Clinical>


LICENCE:
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/daboe01/cappusance?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
