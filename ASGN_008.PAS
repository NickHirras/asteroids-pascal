{*************************************************************************
 *
 *	Programming Assignment 8
 *	by Nicholas Smith (imnes@go.com)
 *	Written on 11/23/2000
 *	Programming Concepts II - Dr. Horn
 *	Pensacola Junior College
 *
 *------------------------------------------------------------------------
 *
 *		This program is an asteroids clone written
 *		entirely in TurboPascal using the BGI library.
 *		It also uses custom keyboard code I wrote.
 *
 *		Things not yet finished/done:
 *			o Make asteroids split into smaller
 *			  chunks instead of just being destroyed
 *			  when first shot.
 *                o Make player initially invulernable when
 *                  they first reappear.
 *
 ************************************************************************}
{$I-}
program Assignment8;
uses Crt, Dos, Graph, Keyboard;


{=========================================================================
 =
 =	Type Definitions, Constants, Globals.
 =
 ========================================================================}
Const
	{ Bullet Info.  Most visually appealing is MAXSHOTS=LIFESPAN=25 }
	MAXSHOTS = 25;		{ How many bullts en route at once? }
        LIFESPAN = 25;		{ How many game cycles bullet is alive? }
        BULLETDELAY = 10;

	{ Asteroids Stuff. }
	MAXASTEROIDS = 255;



Type
 VertexType = Record
	X, Y: Real;
 End;

 ObjectType = Record
 	NumVertices: Integer;
        Vertice: Array [1..16] of VertexType;
	X, Y: Real;  	{ Location of Object's Center on screen. }
        Color: Integer;
        DX, DY: Real;   { Object's Velocity. }
        POV: Real;	{ Object's Point Of View (Angle It's Facing). }
        Alive: Boolean;
 End;


 BulletType = Record
	Total: Integer;
	X, Y: Real;
        DX, DY: Real;
	TTL: Integer;	{ Time left to live. }
	Color: Integer;
	ProcessNext: Integer; { Time until gun can fire next. }
 End;


 BulletsType = Array [1..MAXSHOTS] of BulletType;

 AsteroidsType = Array[1..MAXASTEROIDS] of ObjectType;

 HighScoreEntryType = Record
 	Initials: Array [1..3] of Char;
        Score: LongInt;
 End;

 HighScoreTableType = Array [1..10] of HighScoreEntryType;

Var
 HS: HighScoreTableType;
 W, S: String;
 GameOver: Boolean;
 SpaceShip: ObjectType;
 Bullets: BulletsType;
 i: Integer;
 Asteroids: AsteroidsType;
 ActivePage: Word;
 FastCPU: Boolean;
 Score: LongInt;
 HighScore: LongInt;
 Lives: Integer;
 Done: Boolean;
 Dead: Boolean;
 PointTicker: Integer;
 Wave: Integer;
 Level: Integer;
 LevelCleared: Boolean;
 SecretCode: String;
 God: Boolean;
 FirstGame: Boolean;


 {=========================================================================
 =
 =	Show the error message and die.
 =
 ========================================================================}
Procedure ShowErrorAndDie(MSG: String);
Begin
	RestoreCrtMode;
	WriteLn('');
        WriteLn('*** ERROR ***');
        WriteLn(MSG);
        WriteLn('');
        Halt;
End;



{=========================================================================
 =
 =	Check for secret codes.
 =
 ========================================================================}
Procedure CheckCodes;
Var
	i: Integer;
        s: String;
BEGIN
	if God=True Then
         Begin
         	if KEY[KEY_NPPLUS] Then Begin
                	Inc(Lives);
			Inc(Wave);
                        Dead:=True;
                        LevelCleared:=True;
                        Delay(150);
                        Exit;
                End;

                if KEY[KEY_NPMINUS] Then Begin
                	Inc(Lives);
                	LevelCleared:=True;
                        Inc(Level);
                        Dead:=True;
                        Delay(150);
                        Exit;
                End;

                if KEY[KEY_NPENTER] Then Inc(Lives);
         End;

        if      Key[KEY_I] Then SecretCode[6]:='I'
        Else If Key[KEY_M] Then SecretCode[6]:='M'
        Else If Key[KEY_N] Then SecretCode[6]:='N'
        Else If Key[KEY_E] Then SecretCode[6]:='E'
        Else If Key[KEY_S] Then SecretCode[6]:='S'
        Else Exit;

        Delay(100);

        s:='';
        for i:=1 to 5 Do
	Begin
		SecretCode[i]:=SecretCode[i+1];
                s:=s+SecretCode[i];
        End;

        if s='IMNES' then
        Begin
		if God=True then God:=False else God:=True;
                Score:=HighScore;
        End;
END;


{=========================================================================
 =
 =	Play a sound fx.
 =
 ========================================================================}
Procedure SNDNextWave;
Begin
End;

Procedure SNDBackgroundNoise;
Var
	a: Integer;
Begin
	For a:=1 to 10 Do
        Begin
        	Sound(a+10); Delay(10); NoSound;
        End;
End;

Procedure SNDYouSuck;
Const
	Base=100;
Var
	a, b, c: Integer;
BEGIN
	For a:=10 downto 1 Do
        Begin
		Sound(Base+(a*10)); Delay(50); NoSound; Delay(10);
        End;
        Sound(100); Delay(500); NoSound;
END;


Procedure SNDNewWave;
Const
	Base=300;
        DelayAdjust=7/9;
BEGIN
	Sound(Base); Delay(Round(350*DelayAdjust)); NoSound; Delay(Round(50*DelayAdjust));

        Sound(Base); Delay(Round(70*DelayAdjust)); NoSound; Delay(Round(10*DelayAdjust));
        Sound(Base+25); Delay(Round(125*DelayAdjust)); NoSound; Delay(Round(10*DelayAdjust));
        Sound(Base+50); Delay(Round(125*DelayAdjust)); NoSound; Delay(Round(10*DelayAdjust));

        Sound(Base+100); Delay(Round(500*DelayAdjust)); NoSound;
END;

Procedure SNDBullet;
Begin
	if (GameOver=True) or (Dead=True) then Exit;
	NoSound;
        Sound(350);
        Delay(15);
        NoSound;
End;

Procedure SNDVictory;
Const
	Base=300;
BEGIN
	Sound(Base); Delay(100); NoSound; Delay(50);

        Sound(Base-50); Delay(70); NoSound; Delay(10);
        Sound(Base); Delay(70); NoSound; Delay(10);

        Sound(Base+100); Delay(300); NoSound; Delay(10);
End;

Procedure SNDDie;
Var
	a, b, c: Integer;

BEGIN
         For b:=25 Downto 10 Do
         Begin
         	Sound((b*10));
                Delay(10);
                NoSound;
         End;
End;

Procedure SNDKillAsteroid;
Var
	b: Integer;
BEGIN
         For b:=25 Downto 1 Do
         Begin
         	Sound(b*10);
                Delay(5);
                NoSound;
         End;
End;



{=========================================================================
 =
 =	Get into graphics mode.  Die if there's an error.
 =
 ========================================================================}
Procedure OpenGraphicsWindow;
Var
	GrDriver, GrMode: Integer;
	GrError: Integer;
Begin
	{ Try to get into graphics mode 640x480 VGA. }
	GrDriver:=VGA; GrMode:=VGAMed;
	InitGraph(GrDriver, GrMode, '');

	{ If there's an error, report it and exit. }
	GrError:=GraphResult;
	if GrError <> GrOK then
	   ShowErrorAndDie(GraphErrorMsg(GrError));
End;


{=========================================================================
 =
 =	Convert Degrees to Radians.
 =
 ========================================================================}
Function DegToRad(Angle: Real): Real;
Begin
	DegToRad:=PI*Angle/180;
End;



{=========================================================================
 =
 =	Shutdown the game, get back into text mode, halt the
 =	program's execution.
 =
 ========================================================================}
Procedure Shutdown;
Begin
	SetActivePage(1);
        SetVisualPage(1);

	RestoreCRTMode;

        WriteLn('Thanks for playing!');
        WriteLn('');

	Halt;
End;




{=========================================================================
 =
 =	Load an object from a specified file.  Die on error.
 =	----------------------------------------------------
 =		File Format:
 =			Header = 'OBJECT_FILE'
 =			Number Of Vertices -> Integer
 =			Color of Object -> Integer
 =			X Vertice [1] -> Real
 =			Y Vertice [1] -> Real
 =				.
 =				.
 =				.
 =			X Vertice [N] -> Real
 =			Y Vertice [N] -> Real
 =
 ========================================================================}
Procedure LoadObject(var Obj: ObjectType; filename: string);
Var
	ObjFile: Text;
        i: Integer;
	Header: String;
Begin
	{ Attempt to open the file. }
	Assign(ObjFile, Filename);
        Reset(ObjFile);
	if IoResult<>0 Then	{ We've got problems... }
        	ShowErrorAndDie('Cannot load object file: '+Filename);

	ReadLn(ObjFile, Header);
	if Header<>'OBJECT_FILE' then
        	ShowErrorAndDie('Invalid header in object file '+Filename);

        { Load in the data items.  Abort if EOF is reached early. }
	ReadLn(ObjFile, Obj.NumVertices);
	if EOF(ObjFile) then ShowErrorAndDie('Object File '+Filename+
		    ' is Incomplete or Damaged!');

        ReadLn(ObjFile, Obj.Color);
	if EOF(ObjFile) then ShowErrorAndDie('Object File '+Filename+
                    ' is Incomplete or Damaged!');

	for i:=1 to Obj.NumVertices Do
         Begin
		ReadLn(ObjFile, Obj.Vertice[i].X);
		if EOF(ObjFile) then ShowErrorAndDie('Object File '+Filename+
                    ' is Incomplete or Damaged!');

		ReadLn(ObjFile, Obj.Vertice[i].Y);
		if EOF(ObjFile) then ShowErrorAndDie('Object File '+Filename+
		    ' is Incomplete or Damaged!');
	 End;


	{ Reset other values not saved in the file. }
	Obj.DX :=0; Obj.DY :=0;
	Obj.X  :=0; Obj.Y  :=0;
	Obj.POV:=0;

	Close(ObjFile);

End;


{=========================================================================
 =
 =	Test Speed of Machine.  Return True/False.
 =
 ========================================================================}
Function TooFast: Boolean;
Var
	i: integer;
	h,m,s,hund: word;
	st, et, tt: real;
	G: real;
Begin
	GetTime(h, m, s, hund); st:=(h*3600)+(m*60)+s+(hund/100);

	For i:=1 to 32767 Do
		G:=SQR(COS(i)+SIN(i));

	GetTime(h, m, s, hund); et:=(h*3600)+(m*60)+s+(hund/100);


	tt:=et-st;

	if tt>1 then
		TooFast:=False
	else
		TooFast:=True;
End;




{=========================================================================
 =
 =      Parse keypresses for movement of the space ship.  This will
 =	appropriately update the structure's contents.  The routine
 =	assumes that the bios keyboard handler has been overwritten
 =	with my own code!  It may crash otherwise!!!
 =
 ========================================================================}
Procedure MoveShip(var Obj: ObjectType);
Const
	RotationVelocity=10;	{ How fast to spin when turning. }
	AccelVelocity=1/10;	{ How fast to change acceleration. }
	AccelMax=10;		{ Fastest the ship can go. }

Begin
	{ Accelerate into the desired direction. }
	if Key[KEY_UP] then
	 Begin
         	{ Left - Right }
		if (Obj.POV > DegToRad(0)) AND
		   (Obj.POV < DegToRad(180)) Then
                   	Obj.DX:=Obj.DX+AccelVelocity;
                if (Obj.POV > DegToRad(180)) AND
                   (Obj.POV < DegToRad(360)) Then
			Obj.DX:=Obj.DX-AccelVelocity;

                { Up - Down }
                if (Obj.POV > DegToRad(90)) AND
		   (Obj.POV < DegToRad(270)) Then
                   	Obj.DY:=Obj.DY+AccelVelocity;
		if (Obj.POV > DegToRad(270)) OR
		   (Obj.POV < DegToRad(90)) Then
			Obj.DY:=Obj.DY-AccelVelocity;

                { Max out the velocity. }
		if Obj.DX > AccelMax Then Obj.DX:=AccelMax;
                if Obj.DX < (AccelMax*(-1)) Then Obj.DX:=AccelMax*(-1);

		if Obj.DY > AccelMax Then Obj.DY:=AccelMax;
                if Obj.DY < (AccelMax*(-1)) Then Obj.DY:=AccelMax*(-1);

         End;

            { And update the position. }
		Obj.X:=Obj.X+Obj.DX;
		Obj.Y:=Obj.Y+Obj.DY;

            { Wrap the screen position if necessary. }
		if Obj.X < 0 Then Obj.X:=Obj.X+GetMaxX;
                if Obj.X > GetMaxX Then Obj.X:=Obj.X-GetMaxX;

		if Obj.Y < 0 Then Obj.Y:=Obj.Y+GetMaxY;
		if Obj.Y > GetMaxY Then Obj.Y:=Obj.Y-GetMaxY;


	{ Rotate left / right as requested. If both Left+Right are
          pressed, they will effectively cancel each other out. Also
	  wrap the POV angle around if necessary. }
        if Key[KEY_LEFT] then
         Begin
		Obj.POV:=Obj.POV-(DegToRad(RotationVelocity));
                if Obj.POV<DegToRad(0) then Obj.POV:=Obj.POV+DegToRad(360);
         End;

	if Key[KEY_RIGHT] then
	 Begin
              	Obj.POV:=Obj.POV+(DegToRad(RotationVelocity));
                if Obj.POV>DegToRad(360) then Obj.POV:=Obj.POV-DegToRad(360);
	 End;
End;




{=========================================================================
 =
 =	Rotate an object (used internally by DrawObject(...);
 =
 ========================================================================}
Procedure RotateObject(var Obj: ObjectType);
Var
	T, I: Integer;
        CS, SN: Real;
        NewX, NewY: Real;
Begin
	SN:=Sin(Obj.POV);  CS:=Cos(Obj.POV);
        For i:=1 to Obj.NumVertices Do
         Begin
		NewX:=Obj.Vertice[I].X * CS - Obj.Vertice[I].Y * SN;
                NewY:=Obj.Vertice[I].Y * CS + Obj.Vertice[I].X * SN;

		Obj.Vertice[I].X:=NewX; Obj.Vertice[I].Y:=NewY;
	 End;
End;


{=========================================================================
 =
 =	Draw an object on the screen.  This procedure also takes
 =	care of any pending move's and rotation's encompassing these
 =	tasks into one convenient command.  To move or rotate an
 =	object, just change the structure's appropriate var's.
 =
 ========================================================================}
Procedure DrawObject(Obj: ObjectType; Speed: Boolean);
Var
	i: Integer;
	x, y: Integer;
	Points: Array[1..16] of PointType;
Begin
	{ Rotate our local copy of the object for display. }
	RotateObject(Obj);

	{ Set the color. }
	SetColor(Obj.Color);

	{ Move to the object's first vertice relative to
	  the object's center. }
	Points[1].X:=Round(Obj.X+Obj.Vertice[1].X);
	Points[1].Y:=Round(Obj.Y+Obj.Vertice[1].Y);
	X:=Points[1].X; Y:=Points[1].Y;

	{ Now draw the other vertices. }
	For i:=2 To Obj.NumVertices Do
	 Begin
		X:=X+Round(Obj.Vertice[i].X);
		Y:=Y+Round(Obj.Vertice[i].Y);
		Points[i].X:=X;
		Points[i].Y:=Y;
	 End;

	 Points[Obj.NumVertices+1].X:=Points[1].X;
	 Points[Obj.NumVertices+1].Y:=Points[1].Y;


	{ And now draw it. }
	if Speed=True then Begin
		SetFillStyle(SolidFill, Obj.Color);
		FillPoly(Obj.NumVertices, Points);
	End Else
		DrawPoly(Obj.NumVertices+1, Points);

End;




{=========================================================================
 =
 = 	Init the bullets.
 =
 ========================================================================}
Procedure InitBullets(var Bullets: BulletsType);
Var
	i: Integer;
Begin
	for i:=1 to MAXSHOTS do
        Begin
        	Bullets[i].TTL:=0;
        End;

	Bullets[1].ProcessNext:=BULLETDELAY;
        Bullets[1].Total:=0;
End;


{=========================================================================
 =
 = 	Draw all active bullets onto the screen.
 =
 ========================================================================}
Procedure DrawBullets(var Bullets: BulletsType; Speed: Boolean);
Var
	i: Integer;
Begin
	For i:=1 to MaxShots Do
	 Begin
		if Bullets[i].TTL > 0 Then
			PutPixel(Round(Bullets[i].X),
				 Round(Bullets[i].Y),
				 Bullets[1].Color);
	 End;
End;

{=========================================================================
 =
 =	Move the asteroids.
 =
 ========================================================================}
Procedure MoveAsteroids(var Asteroids: AsteroidsType);
Var
	i: Integer;
Begin
	For i:=1 to MAXASTEROIDS do
         Begin
		if Asteroids[i].Alive = True Then
                 Begin
			{ Move }
			Asteroids[i].X:=Asteroids[i].X+(Asteroids[i].DX*Wave);
			Asteroids[i].Y:=Asteroids[i].Y+(Asteroids[i].DY*Wave);

			{ Wrap }
			if Asteroids[i].X>GetMaxX Then
			   Asteroids[i].X:=Asteroids[i].X-GetMaxX;
                        if Asteroids[i].X<0 Then
                           Asteroids[i].X:=Asteroids[i].X+GetMaxX;

                        if Asteroids[i].Y>GetMaxY Then
			   Asteroids[i].Y:=Asteroids[i].Y-GetMaxY;
			if Asteroids[i].Y<0 Then
                           Asteroids[i].Y:=Asteroids[i].Y+GetMaxY;

                        RotateObject(Asteroids[i]);
		 End;

         End;
End;


{=========================================================================
 =
 =	Draw the asteroids.
 =
 ========================================================================}
Procedure DrawAsteroids(var Asteroids: AsteroidsType; Speed: Boolean);
Var
	i: Integer;
Begin
	For i:=1 to MAXASTEROIDS do
	 Begin
		Asteroids[i].Color:=Asteroids[1].Color;
		if Asteroids[i].Alive = True Then
			DrawObject(Asteroids[i], Speed);
	 End;
End;


{=========================================================================
 =
 =	Handle the guns 'n Ammo.  Fire another bullet if the CTRL
 =	key is down (and max bullets aren't in flight).  Move the
 =	bullets that are currently en route.  Kill bullets that
 =	have been flying too long.
 =
 ========================================================================}
Procedure DoGuns(var Bullets: BulletsType; SpaceShip: ObjectType);
Const
	BulletMoveUnits = 15;
Var
	i: Integer;

        CS, SN: Real;
	X1, Y1, X2, Y2: Real;
Begin
	{ Get our local copy of the ship ready for use. }
        RotateObject(SpaceShip);

	{ Do we need to fire another bullet?  And is there a vacant
	  spot in the bullet database?                              }
	if Bullets[1].ProcessNext>0 Then Dec(Bullets[1].ProcessNext);
	if (((Key[KEY_LCTRL]) OR (Key[KEY_RCTRL])) AND
	    (Bullets[1].Total<MAXSHOTS) AND (Bullets[1].ProcessNext=0)) Then
	 Begin
         	{ Make the noise. }
                SNDBullet;

         	{ Send another bullet. }
                Bullets[1].ProcessNext:=BULLETDELAY;
              	Inc(Bullets[1].Total);

         	{ Find an empty slot. }
                For i:=1 to MAXSHOTS do
		 Begin
                 	if Bullets[i].TTL=0 then
			Begin
                                { Calculate Initial Location. }
				Bullets[i].TTL:=LIFESPAN;
                                Bullets[i].X:=SpaceShip.X+
				              SpaceShip.Vertice[1].X;
                                Bullets[i].Y:=SpaceShip.Y+
					      SpaceShip.Vertice[1].Y;

				{ Calculate Angle and Velocity. }
				{ Notice: I have been having trouble
				  getting this section to work right.
				  The +2.5 adjustment below is for
                                  visual appeal, to make the bullet's
                                  path look more correct.  There are
                                  errors introduced by using different
				  methods to generate slope for the
                                  bullet and ship, and I'm not sure how
                                  to correct it.  This will suffice for
				  now though!                      }
				  X1:=SpaceShip.Vertice[1].X;
  				  Y1:=SpaceShip.Vertice[1].Y;

				  X2:=(SpaceShip.Vertice[2].X+
				       SpaceShip.Vertice[3].X)/2;
			          Y2:=(SpaceShip.Vertice[2].Y+
				       SpaceShip.Vertice[3].Y)/2;

				  Bullets[i].DX:=(X1-X2)+2.5;
				  Bullets[i].DY:=(Y1-Y2)+2.5;

                                { And get out, we only want to setup one! }
				Break;
                        End;
                 End;
         End; { Fire a bullet? }

         { Animate currently active bullets. }
         for i:=1 to MAXSHOTS do
	  Begin
		if Bullets[i].TTL>0 then
                Begin
                	{ Lose some life. }
			Dec(Bullets[i].TTL);
                        if Bullets[i].TTL = 0 Then Dec(Bullets[1].Total);

                        { Move the shot. }
			Bullets[i].X:=Bullets[i].X+Bullets[i].DX;
			Bullets[i].Y:=Bullets[i].Y+Bullets[i].DY;

			{ Wrap screen boundries if needed. }
                        if Bullets[i].X < 0 then
				Bullets[i].X:=Bullets[i].X+GetMaxX;
                        if Bullets[i].X > GetMaxX then
                        	Bullets[i].X:=Bullets[i].X-GetMaxX;

			if Bullets[i].Y < 0 then
			   	Bullets[i].Y:=Bullets[i].Y+GetMaxY;
			if Bullets[i].Y > GetMaxY then
				Bullets[i].Y:=Bullets[i].Y-GetMaxY;

		End;

	  End; { Animate Active Bullets. }

End;



{=========================================================================
 =
 =	Wait for a Vertical Retrace of the Monitor scanning beam.
 =
 ========================================================================}
Procedure WaitRetrace; Assembler;
Label
	l1, l2;
Asm
	mov dx, 3DAh;

	l1:
		in al, dx;
		and al, 08h;
		jnz l1;

	l2:
		in al, dx;
		and al, 08h;
		jz l2;
End;



{=========================================================================
 =
 =	Flip active <-> visual pages.
 =
 ========================================================================}
Procedure Flip(var Page: Word);
Begin
	WaitRetrace;

	if Page=0 then
	 Begin
		Page:=1;
		SetVisualPage(1);
		SetActivePage(0);
	 End
	else
	 Begin
		Page:=0;
		SetActivePage(1);
		SetVisualPage(0);
	 End;
End;



{=========================================================================
 =
 =	Initialize the HUD with default values.
 =
 ========================================================================}
Procedure HUDInit(var HighScore, CurrentScore: LongInt; var Lives: Integer);
Var
	i: Integer;
Begin
        CurrentScore:=0;
        Lives:=3;
        GameOver:=False;
End;


{=========================================================================
 =
 =	Update the On-Screen HUD.
 =
 ========================================================================}
Procedure HUDUpdate(var HighScore, CurrentScore: LongInt; var Lives: Integer;
 	            Obj: ObjectType);
Var
	i: Integer;
        y: Integer;
        s: String;
Begin
	{ Show the scores. }
        if CurrentScore > HighScore then HighScore:=CurrentScore;
        SetColor(14);
        SetTextJustify(CenterText, TopText);
        SetTextStyle(DefaultFont, HorizDir, 2);
        OutTextXY(GetMaxX Div 4, 0, 'PLAYER 1');
        OutTextXY((GetMaxX Div 4)*3, 0, 'HIGH SCORE');
        y:=TextHeight('1')+2;

        SetColor(12);
        Str(CurrentScore, S);
        OutTextXY(GetMaxX Div 4, y, S);
        Str(HighScore, S);
        OutTextXY((GetMaxX Div 4)*3, y, S);

        { Show how many lives we have left. }
        Obj.X:=(GetMaxX/2)-20;  Obj.Y:=10; Obj.POV:=0;
        For i:=1 to Lives Do
         Begin
		DrawObject(Obj, True);
                Obj.X:=Obj.X+13;
         End;

         { Game Over? }
         if GameOver=True then
            Begin
         	SetColor(13);
                SetTextStyle(DefaultFont, HorizDir, 4);
                OutTextXY(GetMaxX Div 2, GetMaxY Div 2, 'GAME OVER');
                SetTextStyle(DefaultFont, HorizDir, 1); SetColor(11);
                OutTextXY(GetMaxX Div 2, GetMaxY Div 2 + 30,
		          'PRESS SPACE TO CONTINUE');
            End
         Else if Dead=True then
	     Begin
         	SetColor(11);
                SetTextStyle(DefaultFont, HorizDir, 1);
                OutTextXY(GetMaxX div 2, GetMaxY div 2,
		          'PRESS SPACE TO CONTINUE');
              End;

         { Am I God? }
         if God=True Then
         Begin
         	SetColor(2);
                SetTextStyle(DefaultFont, HorizDir, 1);
                SetTextJustify(CenterText, BottomText);
                OutTextXY(GetMaxX div 2, GetMaxY, 'GODMODE');
         End;
End;


{=========================================================================
 =
 =	The ship has been hit, we are dead!
 =
 =========================================================================}
Procedure KillShip(Ship: ObjectType);
Var
	i, r: Integer;
        x, y: Integer;
Begin
	SetColor(4);
        SetActivePage(1);
        SetVisualPage(1);
	For i:=1 to 3 Do
        Begin
        	X:=Round(Ship.X)+(Random(20)-10);
                Y:=Round(Ship.Y)+(Random(20)-10);
                For r:=1 to 20 Do
                Begin
                	Delay(1);
                	Circle(X, Y, R);
                End;
		SNDDie;
        End;

        If Lives<0 then GameOver:=True;
        If GameOver=True Then SNDYouSuck;
        Dead:=True;
End;


{=========================================================================
 =
 =  	This routine is called when an asteroid is shot.  For now
 =	I will just show a small explosion and mark the asteroid
 =	as inactive, but
 =
 =========================================================================}
Procedure KillAsteroid(var Asteroids: AsteroidsType; Num: Integer);
Var
	i: Integer;
        x, y: Integer;
Begin
	X:=Round(Asteroids[Num].X); Y:=Round(Asteroids[Num].Y);
        SetActivePage(0); SetVisualPage(0);
        For i:=1 to 255 Do
         Begin
                PutPixel(X+(Random(20)-10), Y+(Random(20)-10), 0);
         End;

         SNDKillAsteroid;
         Asteroids[Num].Alive:=False;
End;


{=========================================================================
 =
 =	This routine handles all collision detection.  Some values of
 =	objects such as bounding boxes for the asteroids and ship are
 =	hard coded and must be redone to reflect changes in the
 =	object matrix files.
 =
 =========================================================================}
Procedure Collision(Ship: ObjectType; var Bullets: BulletsType;
		    var Asteroids: AsteroidsType);
Const
	AstBox=20;
        ShipBox=7;
Var
	i, c: Integer;
        aX1, aY1, aX2, aY2,
        bX1, bY1, bX2, bY2: Real;
Begin
        aX1:=Ship.X-ShipBox;
        aY1:=Ship.Y-ShipBox;
        aX2:=Ship.X+ShipBox;
        aY2:=Ship.Y+ShipBox;

        For I:=1 to MAXASTEROIDS do
        Begin
		if Asteroids[i].Alive = True Then
                Begin
                	bX1:=Asteroids[i].X-AstBox;
                        bY1:=Asteroids[i].Y-AstBox;
                        bX2:=Asteroids[i].X+AstBox;
                        bY2:=Asteroids[i].Y+AstBox;

                        { See if the ship ran into this asteroid. }
                        if ((((ax1>bX1) and (ax1<bX2))  OR
                             ((ax2>bX1) and (ax2<bX2))) AND
                            (((aY1>bY1) and (ay1<bY2))  OR
                            ((aY2>bY1) and (aY2<By2)))) AND
			    (God=False) Then
                            Begin
                            	KillShip(Ship);
                                Break;
                            End;

                        { See if any of our bullets hit this asteroid. }
                        for c:=1 to MAXSHOTS do
                        Begin
                        	if Bullets[c].TTL>0 then
                                  if ((Bullets[c].X>bX1) and
                                      (Bullets[c].X<bX2) and
                                      (Bullets[c].Y>bY1) and
                                      (Bullets[c].Y<bY2)) Then
                                      Begin
					KillAsteroid(Asteroids, i);
                                        Score:=Score+(100*Wave);
                                        Bullets[c].TTL:=0;
                                      End;
                        End;
                End;
        End;
End;



{=========================================================================
 =
 =	Allow the user to enter their initials.
 =
 ========================================================================}
Function GetPlayerInitials: String;
Var
	S: String[3];
        Done: boolean;
        CX, CY: Integer;
        DX, DY: Integer;
        X, Y: Array[1..28] of Integer;
        A: Integer;
        PlayerName: String;
Begin
	S:=''; PlayerName:='';
        Done:=False;

        SetActivePage(ActivePage);
        SetVisualPage(ActivePage);
        ClearViewPort;

        SetTextStyle(DefaultFont, HorizDir, 4);
        SetColor(15);
        SetTextJustify(CenterText, TopText);
        OutTextXY(GetMaxX Div 2, 0, 'HALL OF FAME');
        SetTextStyle(DefaultFont, HorizDir, 3);
        SetTextJustify(CenterText, BottomText);
        OutTextXY(GetMaxX Div 2, GetMaxY, 'ENTER YOUR INITIALS');

        { Fill the screen with a grid of characters. }
        SetTextStyle(DefaultFont, HorizDir, 7);
        SetColor(14);
        SetTextJustify(LeftText, TopText);
	CX:=3; CY:=TextHeight('A');
        DX:=TextWidth('A')+10;
        DY:=TextHeight('A')+10;
        For A:=1 to 26 Do
	Begin
        	S:=Chr(A+64);
        	OutTextXY(CX, CY, S);
                X[A]:=CX; Y[A]:=CY;
                CX:=CX+DX;
                If CX+DX > GetMaxX Then
                 Begin
                 	CY:=CY+DY;
                        CX:=3;
                 End;
        End;

        S:=Chr(27);
        	OutTextXY(CX, CY, S);
                X[27]:=CX; Y[27]:=CY;
                CX:=CX+DX;
                If CX+DX > GetMaxX Then
                 Begin
                 	CY:=CY+DY;
                        CX:=3;
                 End;

	A:=1;
        SetTextJustify(CenterText, BottomText);
        While Done=False Do
        Begin
                CX:=X[A]; CY:=Y[A];

                WaitRetrace;
                SetColor(4); SetLineStyle(SolidLn, 0, 3);
                Rectangle(CX-3, CY-3, CX+DX-11, CY+DY-11);
                Delay(75);

		if Key[KEY_ESC] then Begin
			PlayerName:='---';
			Break;
                End
                Else if Key[KEY_UP] or Key[KEY_LEFT] Then Dec(A)
                Else if Key[KEY_DOWN] or Key[KEY_RIGHT] Then Inc(A)
                Else if Key[KEY_BACKSPACE] Then
		 Begin
                               	if Length(PlayerName)<=1 Then
                                	PlayerName:=''
                                Else Begin
                                	S:='';
                                	For i:=1 to Length(PlayerName)-1 Do
						S:=S+PlayerName[i];
                                        PlayerName:=S;
                                End;
                 End
        	Else if Key[KEY_LCTRL] or Key[KEY_RCTRL] or Key[KEY_ENTER]
                                       or Key[KEY_SPACE]
		Then Begin
                	if (Length(PlayerName)>=3) AND (A<27) Then
			  Done:=True Else
                        if A<27 Then PlayerName:=PlayerName+CHR(A+64)
                        Else
                        	if Length(PlayerName)<=1 Then
                                	PlayerName:=''
                                Else Begin
                                	S:='';
                                	For i:=1 to Length(PlayerName)-1 Do
						S:=S+PlayerName[i];
                                        PlayerName:=S;
                                End;
                End;

                If A>27 Then A:=1;
                If A<1 Then A:=27;

                SetColor(0); SetLineStyle(SolidLn, 0, 3);
                Rectangle(CX-3, CY-3, CX+DX-11, CY+DY-11);

                SetColor(0); SetLineStyle(SolidLn, 0, 1);
                SetFillStyle(1, 0);
                Bar(0, GetMaxY-45-DX, GetMaxX, GetMaxY-45);
                SetColor(14);
                S:=PlayerName+'---';
		OutTextXY(GetMaxX Div 2, GetMaxY-45, S);
        End;

        GetPlayerInitials:=PlayerName;
End;


{=========================================================================
 =
 =	Save the High Score table to Disk.
 =
 ========================================================================}
Procedure SaveHighScores(var Table: HighScoreTableType; Filename: String;
			 PlayerScore, HighScore: LongInt);
Var
	F: File of HighScoreTableType;
        i, n: Integer;
        s: String;
Begin
	{ See if the player deserves a spot in the hall of fame! }
        if (HighScore=Score) AND (GameOver=True) Then
         { Tell the player they are the best! }
        Begin
        	SetActivePage(ActivePage);
                SetVisualPage(ActivePage);
        	ClearViewPort;
                SetColor(14);
                SetTextStyle(DefaultFont, HorizDir, 4);
                OutTextXY(GetMaxX div 2, GetMaxY div 3, 'CONGRATULATIONS!');
        	SNDNewWave;
                DELAY(1000);

                SetColor(12);
                SetTextStyle(DefaultFont, HorizDir, 2);
                OutTextXY(GetMaxX div 2, (GetMaxY div 3)*2,
		           'YOU''VE BEATEN THE TOP HIGH SCORE!');

		DELAY(3000);
        End;

	{ Bump any beaten users down the list! }
        if GameOver=True Then
        Begin
	        for i:=1 to 10 Do
	         Begin
	         	if PlayerScore>Table[i].Score Then
	                Begin
	                	For n:=10 Downto i+1 Do
	                        Begin
				  Table[i].Score:=Table[i-1].Score;
	                          Table[i].Initials:=Table[i-1].Initials;
	                        End;

	                        Table[i].Score:=PlayerScore;
	                        S:=GetPlayerInitials;
                                Table[i].Initials[1]:=S[1];
                                Table[i].Initials[2]:=S[2];
                                Table[i].Initials[3]:=S[3];
	                        Break;
	                End;
	         End;
        End;

        { Write out the file. }
	Assign(F, Filename);
        Rewrite(F);
        Write(F, Table);
        Close(F);
End;


{=========================================================================
 =
 =	Load the High Score table into ram.
 =
 ========================================================================}
Procedure LoadHighScores(var Table: HighScoreTableType; Filename: String;
                         var PlayerScore, HighScore: LongInt);
Var
	f: File of HighScoreTableType;
        i: Integer;
Begin
	{ First, try to open the file. }
        Assign(f, Filename);
        Reset(f);

        { If we can't open the file, then set some generic values, and exit }
        if IOResult<>0 Then
        Begin
        	Table[1].Initials:=('NES');
                Table[1].Score:=32750;

                Table[2].Initials:=('BEN');
                Table[2].Score:=32600;

                For i:=3 to 10 Do
                 Begin
                 	Table[i].Initials:=('---');
                        Table[i].Score:=0;
                 End;
        End
        Else
        Begin
	        { If we CAN open it, then load the values in... }
        	Read(f, Table);
	        Close(f);
        End;

        For i:=1 to 10 Do
	   if Table[i].Score>HighScore then HighScore:=Table[i].Score;

End;


{=========================================================================
 =
 =	Show the High Score Table.
 =
 ========================================================================}
Procedure ShowHighScores(Table: HighScoreTableType);
Var
	cx, i: Integer;
        S: String;
Begin
	SetActivePage(ActivePage);
        SetVisualPage(ActivePage);
        ClearViewPort;

	SetTextStyle(DefaultFont, HorizDir, 4);
        SetTextJustify(CenterText, CenterText);
        SetColor(14);
        CX:=TextHeight('A');

        OutTextXY(GetMaxX Div 2, GetMaxY Div 10-(CX Div 2), 'HALL OF FAME');

        SetColor(7); SetTextJustify(LeftText, CenterText);
        For i:=1 to 10 Do
        Begin
        	Str(Table[i].Score, S);
        	OutTextXY(GetMaxX Div 2-150, (GetMaxY Div 10)*(i+1)+20,
                          Table[i].Initials+'  '+S);
                Delay(150);
        End;


        For i:=1 to 1000 Do
        Begin
        	Delay(10);
		if Key[KEY_ESC] then Break;
        End;
End;


{=========================================================================
 =
 =	M A I N     C O D E
 =
 ========================================================================}
BEGIN
        ClrScr;
        WriteLn('Welcome to my Asteroids clone!  This game was written as');
        WriteLn('Programming Assignment #8 for Programming Concepts II on');
        WriteLn('Thanksgiving 2000 by Nicholas Smith (imnes@go.com).');
        WriteLn('');
	WriteLn('Keys:');
        WriteLn('=====');
        WriteLn('     LEFT/RIGHT ARROWS - Steer the ship');
        WriteLn('     UP ARROW          - Accelerate');
        WriteLn('     CTRL              - Fire Cannon');
        WriteLn('     P                 - Pause');
        WriteLn('     ESC               - Quit');
        WriteLn('');
        WriteLn('Every three levels completed you will be awarded an extra');
        WriteLn('life.  You can have up to five lives max.');
        WriteLn('');
	Write('Timing CPU, please wait this may take up to one minute...');
	FastCPU:=TooFast;
	WriteLn;
        Done:=False;
        Level:=1; Wave:=1;
        WriteLn('Press any key to begin...');
        ReadKey;

	Randomize;
	OpenGraphicsWindow;

	LoadObject(SpaceShip, 'SHIP.OBJ');
        HUDInit(HighScore, Score, Lives);
        God:=False; FirstGame:=True;

	CreateKeyboard;
        GameOver:=True;

   While Done=False Do
   Begin
   	LoadHighScores(HS, 'SCORES.HI', Score, HighScore);
	SpaceShip.X:=GetMaxX/2; SpaceShip.Y:=GetMaxY/2;
        SpaceShip.POV:=0; SpaceShip.DX:=0; SpaceShip.DY:=0;

	for i:=1 to Level*2 do
	 Begin
		LoadObject(Asteroids[i], 'ASTEROIDS.OBJ');

		Asteroids[i].X:=Random(GetMaxX);
		Asteroids[i].Y:=Random(GetMaxY);
		Asteroids[i].Color:=10;
		Asteroids[i].POV:=DegToRad(Random(5));
		Asteroids[i].DX:=Random(5);
		Asteroids[i].DY:=Random(5);
		if (Random(3)=1) Then
			Asteroids[i].Alive:=False
		Else
			Asteroids[i].Alive:=True;
	 End;
         { Make sure we have at least one asteroid. }
	 Asteroids[1].Alive:=True;

	InitBullets(Bullets);

        While True=True do
	 Begin

         	{ Quit? }
                if Key[KEY_ESC] then Begin
			Done:=True;
                        GameOver:=True;
                        Break;
                End;

                { Pause? }
                if Key[KEY_P] then Begin
                	Delay(250);
                        While Not Key[KEY_P] Do;
                        Delay(250);
                End;

		{ Flip the active pages over. }
		Flip(ActivePage);

		{ Erase the old objects on the screen. }
		ClearViewPort;

		{ Process any keypresses and advance animations. }
		MoveShip(SpaceShip);
		DoGuns(Bullets, SpaceShip);
		MoveAsteroids(Asteroids);

		{ Redraw objects in new positions.  Check for collisions. }
                if (GameOver=False) and (Dead=False) then
                Begin
			SpaceShip.Color:=7;DrawObject(SpaceShip, FastCPU);
			Bullets[1].Color:=10; DrawBullets(Bullets, FastCPU);
                        Collision(SpaceShip, Bullets, Asteroids);
                 End
                Else
                 Begin
                	if Key[KEY_SPACE] then
                        	if GameOver=True then
				 Begin
                                        if FirstGame=False Then
					  SaveHighScores(HS, 'SCORES.HI',
					                 Score, HighScore);
                                        FirstGame:=False;
				        HUDInit(HighScore, Score, Lives);
                                        Level:=1; Wave:=1;
                                        Lives:=3;
		                        Asteroids[i].Alive:=True;
                		        For i:=2 to MAXASTEROIDS do
		                          Asteroids[i].Alive:=False;
                                        Dead:=False;
                                        GameOver:=False;
				 	Break;
                                 End
	                        Else
        	                 Begin
                                        SNDVictory;
                	         	Dead:=False;
                                        Dec(Lives);
					SpaceShip.X:=GetMaxX / 2;
                                	SpaceShip.Y:=GetMaxY / 2;
	                                SpaceShip.POV:=0;
        	                        SpaceShip.DX:=0; SpaceShip.DY:=0;
	                         End;
                End;
		Asteroids[1].Color:=6; DrawAsteroids(Asteroids, FastCPU);

                { Show the HUD stats. }
                if (Dead=False) and (LevelCleared=False) and (GameOver=False)
		   Then Inc(PointTicker);
                if PointTicker>100 Then
                 Begin
                 	PointTicker:=0;
                        Score:=Score+(5*Wave);
                 End;
                HUDUpdate(HighScore, Score, Lives, SpaceShip);

                { Is this level cleared? }
                LevelCleared:=True;
                For i:=1 to Level*2 Do
                Begin
                	if Asteroids[i].Alive=True then
			 Begin
			 	LevelCleared:=False;
                                Break;
                         End;
                End;

                { Intermission... }
                While LevelCleared=True Do
                Begin
                	{ Show some info... }
                        SetTextStyle(DefaultFont, HorizDir, 2);
                        SetColor(15);
                        Str(Level, S); Str(Wave, W);
                        OutTextXY((GetMaxX div 2), (GetMaxY div 3)*1,
                        	'WAVE '+W+' LEVEL '+S+' COMPLETE!');
                        OutTextXY((GetMaxX div 2), (GetMaxY div 3)*2,
                        	'PRESS SPACEBAR TO CONTINUE');

			{ Flip the active pages over. }
			Flip(ActivePage);

			{ Erase the old objects on the screen. }
			ClearViewPort;

			{ Process any keypresses and advance animations. }
			MoveShip(SpaceShip);
			DoGuns(Bullets, SpaceShip);
			SpaceShip.Color:=7;DrawObject(SpaceShip, FastCPU);
			Bullets[1].Color:=10; DrawBullets(Bullets, FastCPU);
                        HUDUpdate(HighScore, Score, Lives, SpaceShip);


                        { Exit when a key is hit. }
                        if Key[KEY_SPACE] then
                        	Break;
                End;

                If LevelCleared=True Then
                       Begin
				Inc(Level);
                                LevelCleared:=False;
                                if Level>10 then Begin
					Level:=1;
                                        Inc(Wave);
                                        if Wave>3 Then Begin
                                        	SetActivePage(ActivePage);
                                                SetVisualPage(ActivePage);
                                        	SNDVictory;
                                                SNDNextWave;
                                                Score:=Score*2;
                                                Wave:=1;
                                                SetTextStyle(DefaultFont,
                                                             HorizDir, 2);
                                                SetColor(10);
                                                SetTextJustify(CenterText,
                                                               CenterText);
                                                OutTextXY(GetMaxX Div 2,
                                                          (GetMaxY Div 2)-10,
						'YOU''VE COMPLETED THE FINAL WAVE!');
                                                Delay(1000);
                                                OutTextXY(GetMaxX Div 2,
                                                          (GetMaxY Div 2)+110,
						'DOUBLE SCORE BONUS ACHEIVED!');

                                                Delay(5000);
                                        End;
                                        SNDNextWave;
                                End;
                                if (Level MOD 3)=0 then Inc(Lives);
                                if Lives>5 Then Lives:=5;
                                Break;
                        End;


         	{ Check for secret codes. }
                CheckCodes;

		{ Play some background sounds. }
                {SndBackgroundNoise; <-- REMOVED - TOO SLOW! }


		{ Repeat as desired (until ESC is hit)...}
	 End;

         SaveHighScores(HS, 'SCORES.HI', Score, HighScore);
         if (Done=False) and (LevelCleared=True) then Else SNDVictory;
        End;

        ShowHighScores(HS);

	DestroyKeyboard;
	Shutdown;
END.
