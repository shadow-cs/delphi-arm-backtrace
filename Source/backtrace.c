/******************************************************************************/
/*                                                                            */
/*           Copyright (c) 2014 Jan Rames                                     */
/*                                                                            */
/******************************************************************************/
/*                                                                            */
/*           This Source Code Form is subject to the terms of the             */
/*                                                                            */
/*                      Mozilla Public License, v. 2.0.                       */
/*                                                                            */
/*           If a copy of the MPL was not distributed with this file,         */
/*           You can obtain one at http://mozilla.org/MPL/2.0/.               */
/*                                                                            */
/******************************************************************************/

int get_frame()
{
	//We need to get previous frame pointer since Delphi will add another stack
	//frame before calling this function
	asm("\
		ldr r0,[r7] \n\
	");
}
