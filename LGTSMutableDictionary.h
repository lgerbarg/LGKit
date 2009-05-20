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
//  LGTSMutableDictionary.h
//  LGTSMutableDictionary
//
//  Created by Louis Gerbarg on 5/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

extern int32_t gObjectAllocs;

#include <libkern/OSAtomic.h>

@interface LGTSMutableDictionary : NSMutableDictionary {
	void * volatile CXXHorrorShow;
	OSSpinLock rootLock;
}
	
@end

@interface LGTSMutableDictionary (Debugging)
- (void) printGraph;
- (void) validate;
@end
