package com.events
{
	import flash.events.Event;

	public class FileSelectorEvent extends Event
	{
		private var _csv:Boolean;
		private var _read:Boolean;
		private var _peptide:Boolean;
		private var _nucleotide:Boolean;
		private var _image:Boolean;
		private var _libRead:Boolean;
		private var _librRNA:Boolean;
		private var _libtRNA:Boolean;
		private var _libPeptide:Boolean;
		private var _libNucleotide:Boolean;
		
		public static const FILE_SELECTOR_EVENT:String = "FileSelectorEvent";
		
		public function FileSelectorEvent()
		{
			super(FILE_SELECTOR_EVENT,true,true);
			csv=false;
			read=false;
			peptide=false;
			nucleotide=false;
			image=false;
			libRead=false;
			librRNA=false;
			libtRNA=false;
			libPeptide=false;
			libNucleotide=false;
		}
		
		public function get libNucleotide():Boolean
		{
			return _libNucleotide;
		}

		public function set libNucleotide(value:Boolean):void
		{
			_libNucleotide = value;
		}

		public function get libPeptide():Boolean
		{
			return _libPeptide;
		}

		public function set libPeptide(value:Boolean):void
		{
			_libPeptide = value;
		}

		public function get libRead():Boolean
		{
			return _libRead;
		}

		public function set libRead(value:Boolean):void
		{
			_libRead = value;
		}
		
		public function get librRNA():Boolean
		{
			return _librRNA;
		}
		
		public function set librRNA(value:Boolean):void
		{
			_librRNA = value;
		}
		
		public function get libtRNA():Boolean
		{
			return _libtRNA;
		}
		
		public function set libtRNA(value:Boolean):void
		{
			_libtRNA = value;
		}
		
		public function get image():Boolean
		{
			return _image;
		}

		public function set image(value:Boolean):void
		{
			_image = value;
		}

		public function get nucleotide():Boolean
		{
			return _nucleotide;
		}

		public function set nucleotide(value:Boolean):void
		{
			_nucleotide = value;
		}

		public function get peptide():Boolean
		{
			return _peptide;
		}

		public function set peptide(value:Boolean):void
		{
			_peptide = value;
		}

		public function get read():Boolean
		{
			return _read;
		}

		public function set read(value:Boolean):void
		{
			_read = value;
		}

		public function get csv():Boolean
		{
			return _csv;
		}

		public function set csv(value:Boolean):void
		{
			_csv = value;
		}

		override public function clone():Event{
			return new FileSelectorEvent();
		}
		
		public function getFileSelectorObject():Object{
			var obj:Object = new Object();
			obj['csv'] = csv;
			obj['nucleotide'] = nucleotide;
			obj['peptide'] = peptide;
			obj['read'] = read;
			obj['image'] = image;
			obj['libRead'] = libRead;
			obj['librRNA'] = librRNA;
			obj['libtRNA'] = libtRNA;
			obj['libPeptide'] = libPeptide;
			obj['libNucleotide'] = libNucleotide;
			
			return obj;
		}
		
	}
}