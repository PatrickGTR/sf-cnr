/*
	PROJECT		<>	SA:MP Anticheat Plug-in
	LICENSE		<>	See LICENSE in the top level directory.
	AUTHOR(S)	<>	Lorenc_ (zeelorenc@hotmail.com)
	PURPOSE		<>  Providing datastructures for the internal SA:MP Server.


	Copyright (C) 2014 SA:MP Anticheat Plug-in.

	The Project is available on https://github.com/myudev/SAMPAC

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program; if not, see <http://www.gnu.org/licenses/>.
*/

#include 							< a_samp >
#include 							< foreach >

#if !defined AC_INCLUDED
	#include 						< anticheat\global >
	#include 						< anticheat\player >

	#include 						< anticheat\hitpoints >
	#include 						< anticheat\weapon >
	//#include 						< anticheat\spectate >
	#include 						< anticheat\airbrake >
	#include 						< anticheat\proaim >
	#include 						< anticheat\autocbug >
	#include 						< anticheat\flying >

	#include 						< anticheat\hooks >

	#define AC_INCLUDED
#endif