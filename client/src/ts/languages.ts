import { InboundPort, OutboundPort } from "../elm/ManyDecks";
import { default as Fuse } from "fuse.js";
import subtag from "subtag";
import registry from "language-subtag-registry/data/json/registry.json";
import language from "language-subtag-registry/data/json/language.json";
import region from "language-subtag-registry/data/json/region.json";

const indexes = {
  language,
  region,
};

export interface Tag {
  code: string;
  type: string;
  description: string;
}

interface CodeAndDescriptions {
  code: string;
  type: string;
  descriptions: string[];
}

function* index(type: keyof typeof indexes): Iterable<CodeAndDescriptions> {
  for (const [code, index] of Object.entries(indexes[type])) {
    const entry = registry[index];
    if (entry.Deprecated === undefined)
      yield {
        code,
        type,
        descriptions: entry.Description,
      };
  }
}

const searchConfig = {
  keys: ["descriptions"],
  minMatchCharLength: 3,
  threshold: 0.15,
  distance: 10,
  includeMatches: true,
};
const searcher = new Fuse(
  [...index("language"), ...index("region")],
  searchConfig
);

function* findTagsByDescription(query: string): Iterable<Tag> {
  const results = searcher.search(query);
  for (const result of results) {
    if (result.matches) {
      for (const match of result.matches) {
        if (match.value) {
          yield {
            code: result.item.code,
            type: result.item.type,
            description: match.value,
          };
        }
      }
    }
  }
}

export const registerPorts = (
  search: InboundPort<string>,
  results: OutboundPort<Tag[]>,
  expand: InboundPort<string>,
  expanded: OutboundPort<Tag[]>
) => {
  let active: number | undefined = undefined;
  search.subscribe((query) => {
    clearTimeout(active);
    active = window.setTimeout(() => {
      active = undefined;
      const tags = findTagsByDescription(query);
      results.send([...tags]);
    }, 200);
  });
  expand.subscribe((code) => {
    expanded.send([...getSubTags(code)]);
  });
};

export function* getSubTags(code: string) {
  const { language, region } = subtag(code);
  if (language !== "") {
    const index = indexes.language[language as keyof typeof indexes.language];
    if (index !== undefined) {
      yield {
        code: language,
        type: "language",
        description: registry[index].Description[0],
      };
    }
  }
  if (region !== "") {
    const index =
      indexes.region[region.toLowerCase() as keyof typeof indexes.region];
    if (index !== undefined) {
      yield {
        code: region,
        type: "region",
        description: registry[index].Description[0],
      };
    }
  }
}
