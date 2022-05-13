console.log('locked and loaded');

function addToggle(s, t) {
    s.addEventListener('click', ()=>{t.forEach((e)=>{e.classList.toggle('active');})});
}

let parser = new DOMParser();
let text = `
<svg id="menu-button" viewBox="0 0 8 8" xmlns="http://www.w3.org/2000/svg">
    <g class="g-menu">
        <line y1="2" y2="2" x1="2" x2="4"/>
        <line y1="2" y2="2" x1="4" x2="6"/>
        <line y1="4" y2="4" x1="2" x2="4"/>
        <line y1="4" y2="4" x1="4" x2="6"/>
        <line y1="6" y2="6" x1="2" x2="4"/>
        <line y1="6" y2="6" x1="4" x2="6"/>
    </g>
</svg>
`;

let svg = parser.parseFromString(text, 'image/svg+xml');

document.body.append(svg.documentElement);

let bla = document.getElementById('menu-button');
let blub = bla.getElementsByClassName('g-menu')[0];
let menu = document.getElementById('menu');

addToggle(bla, [menu, blub]);
