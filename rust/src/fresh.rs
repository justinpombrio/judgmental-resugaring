use std::fmt;
use std::hash;
use std::hash::Hash;
use std::collections::HashMap;
use std::collections::HashSet;


// Public //

pub type Name = String;

pub struct Atom {
    name: Name,
    id: Id
}

impl Clone for Atom {
    fn clone(&self) -> Atom {
        self.check_fresh();
        Atom{
            name: self.name.clone(),
            id: self.id
        }
    }
}

impl Atom {
    pub fn new(name: Name) -> Atom {
        Atom{
            name: name,
            id:   0
        }
    }

    pub fn is_fresh(&self) -> bool {
        self.id != 0
    }

    fn check_fresh(&self) {
        if !self.is_fresh() {
            panic!("Encountered non-fresh atom: {}", self.name);
        }
    }
}

pub trait HasAtoms {
    fn atoms(&mut self) -> HashSet<&mut Atom>;
}

pub trait Freshable : Clone {
    fn freshen(&mut self, state: &mut Freshener);
}

impl<A, B> Freshable for (A, B) where A : Freshable, B : Freshable {
    fn freshen(&mut self, state: &mut Freshener) {
        self.0.freshen(state);
        self.1.freshen(state);
    }
}

pub struct Fresh<T> {
    data:  T
}

impl<T> Fresh<T> where T : Freshable {
    pub fn new(data: T) -> Fresh<T> {
        Fresh{
            data: data
        }
    }

    pub fn freshen(&self) -> T {
        let mut freshener = Freshener::new();
        let mut data = self.data.clone();
        data.freshen(&mut freshener);
        data
    }
}


// Private //

type Id = usize;

impl PartialEq for Atom {
    fn eq(&self, other: &Atom) -> bool {
        self.check_fresh();
        self.id == other.id
    }
}

impl Eq for Atom {}

impl Hash for Atom {
    fn hash<H>(&self, state: &mut H) where H: hash::Hasher {
        self.check_fresh();
        self.id.hash(state)
    }
}

impl fmt::Display for Atom {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        self.check_fresh();
        write!(f, "{}", self.name)
    }
}

impl Freshable for Atom {
    fn freshen(&mut self, freshener: &mut Freshener) {
        if self.is_fresh() {
            panic!("Attempted to freshen an already fresh atom: {}", self.name);
        }
        self.id = freshener.insert(&self.name);
    }
}

pub struct Freshener {
    curr_id: Id,
    mapping: HashMap<Name, Id>
}

impl Freshener {
    fn new() -> Freshener {
        Freshener{
            curr_id: 0,
            mapping: HashMap::new()
        }
    }

    fn insert(&mut self, name: &Name) -> Id {
        match self.mapping.get(name) {
            Some(&id) => id,
            None => {
                self.curr_id += 1;
                self.mapping.insert(name.clone(), self.curr_id);
                self.curr_id
            }
        }
    }
}