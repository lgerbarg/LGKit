/*
  Copyright 2009 Louis Gerbarg
 
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
 
       http://www.apache.org/licenses/LICENSE-2.0
 
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

//
//  LGTSMutableDictionary.m
//  LGTSMutableDictionary
//
//  Created by Louis Gerbarg on 5/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LGTSDictionaryEnumerator.h"
#import "LGTSMutableDictionaryNode.h"
#import "LGTSMutableDictionary.h"

@implementation LGTSMutableDictionary

#pragma mark -
#pragma mark Basic init dealloc stuff

- (id) initWithRootNode:(LGTSMutableDictionaryNode *)rootNode {
	self = [super init];
	
	if (self) {
		rootLock = OS_SPINLOCK_INIT;
		CXXHorrorShow = (void *)rootNode;
	}
	
	return self;
}

- (void) dealloc {
	LGTSMutableDictionaryNode *rootNode = (LGTSMutableDictionaryNode *)CXXHorrorShow;
	if (rootNode) rootNode->release();

	[super dealloc];
}

#pragma mark -
#pragma mark Utility functions

- (LGTSMutableDictionaryNode *) stabilizedRootNode {
	OSSpinLockLock(&rootLock);
	LGTSMutableDictionaryNode *retval = (LGTSMutableDictionaryNode *)CXXHorrorShow;
	if (retval) retval->retain();
	OSSpinLockUnlock(&rootLock);
	
	return retval;
}

- (BOOL) replaceRootNode:(LGTSMutableDictionaryNode *)rootNode withNewRootNode:(LGTSMutableDictionaryNode *)newRoot {
	BOOL retval;
	
	OSSpinLockLock(&rootLock);
	LGTSMutableDictionaryNode *oldRootNode = (LGTSMutableDictionaryNode *)CXXHorrorShow;
	if (rootNode == oldRootNode) {
		CXXHorrorShow = (void *)newRoot;
		if (rootNode) rootNode->release();
		retval = YES;
	} else {
		retval = NO;
	}
	OSSpinLockUnlock(&rootLock);
	
	return retval;

}

- (NSUInteger)count {
	LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
	NSUInteger retval = 0;
	
	if (rootNode) {
		retval = rootNode->getCount();
		rootNode->release();
	}
	
	return retval;
}

- (void) printGraph {
	LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
	
	if (rootNode) {
		rootNode->printGraph();
		rootNode->release();
	}
}

- (id)objectForKey:(id)aKey {
	id retval = nil;
	
	LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
	
	if (rootNode) {
		LGTSMutableDictionaryNode *dataNode = rootNode->nodeForKey(aKey);
		if (dataNode) {
			retval = dataNode->getKey();
		}
		rootNode->release();
	}
	
	return retval;
}

#pragma mark -
#pragma mark Enumeration functions

- (NSEnumerator *)keyEnumerator {
	return [[[LGTSDictionaryEnumerator alloc] initWithRootNode:[self stabilizedRootNode] objectEnumerator:NO] autorelease];
}

- (NSEnumerator *)objectEnumerator {
	return [[[LGTSDictionaryEnumerator alloc] initWithRootNode:[self stabilizedRootNode] objectEnumerator:YES] autorelease];
}

//This is so skanky...
//FIXME this will probably not work correctly under GC
//DISABLE for now, I broke something in fast enum

#if 0
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    if (state->state == 0) {
		state->state = (unsigned long)[[LGTSDictionaryEnumerator alloc] initWithRootNode:[self stabilizedRootNode] objectEnumerator:NO];
		state->mutationsPtr = (unsigned long *)self;
    }
	
	NSUInteger retval = [(LGTSDictionaryEnumerator *)state->state countByEnumeratingWithState:state objects:stackbuf count:len];
	
	if (!retval) {
		[(LGTSDictionaryEnumerator *)state->state release];
	}
	
	return retval;
}
#endif

#pragma mark -
#pragma mark Object manipulation functions

- (void)setObject:(id)anObject forKey:(id)aKey {
	BOOL replaceSuccessful = NO;

	while (!replaceSuccessful) {
		LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
		LGTSMutableDictionaryNode *newRoot = rootNode->insert([[aKey copy] autorelease], anObject);
		//assert(newRoot != rootNode);

		replaceSuccessful = [self replaceRootNode:rootNode withNewRootNode:newRoot];

		if (!replaceSuccessful) {
			newRoot->release();
		}
		if (rootNode) rootNode->release();
	}
}

- (void)removeObjectForKey:(id)aKey {	
	BOOL replaceSuccessful = NO;
	
	while (!replaceSuccessful) {
		LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
		LGTSMutableDictionaryNode *newRoot = rootNode->remove(aKey);
		//assert(newRoot != rootNode);
		
		replaceSuccessful = [self replaceRootNode:rootNode withNewRootNode:newRoot];
		
		if (!replaceSuccessful) {
			newRoot->release();
		}
		if (rootNode) rootNode->release();
	}
	
}

#pragma mark -
#pragma mark Copy protocol functions

// It would be nice to make a readonly subclass

- (id) copy {
	LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
	return [[LGTSMutableDictionary alloc] initWithRootNode:rootNode];
}

- (id) mutableCopy {
	LGTSMutableDictionaryNode *rootNode = [self stabilizedRootNode];
	return [[LGTSMutableDictionary alloc] initWithRootNode:rootNode];
}

@end
