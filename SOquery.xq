declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare option saxon:output "doctype-system=intermediate.dtd";
declare option saxon:output "indent=yes";

declare function local:max-string($strings as xs:anyAtomicType*) as xs:string? 
{
   max(for $string in $strings return string($string))
 } ;

declare function local:getBadges($user as node()) as node()*
{
	for $badge in doc("Badges.xml")/badges/row[./@UserId  = $user/@Id]
	return
		<badge>{data($badge/@Name)}</badge>
};

declare variable $threshold as xs:integer external;  

<result>{

let $list := doc("Users.xml")//users/row[./@Reputation > $threshold]

return
	if(fn:empty($list))
	then	
			<error>Users not found</error>
	else 
		<users>{
			for $user in $list
			let $posts := doc("Posts.xml")/posts/row[./@OwnerUserId = $user/@Id]
			let $maxScore := fn:max($posts/@Score)
			let $posts := $posts[./@Score = $maxScore]
			let $lastDate := local:max-string($posts/@CreationDate)
			let $topPost := $posts[(./@Score = $maxScore) and (./@CreationDate = $lastDate)]
			let $topPost := if (fn:empty($topPost)) then <post Body="No posts were found for this user!"/> else $topPost
			let $description := data($user/@AboutMe)
			let $description := if(fn:empty($description)) then "Apparently, this user prefers to keep an air of mystery about them." else $description
			order by xs:integer($user/@Reputation) descending
			return
				<user id="{data($user/@Id)}">
					<name>{data($user/@DisplayName)}</name>
					<description>{$description}</description>
					<location>{data($user/@Location)}</location>
					<reputation>{data($user/@Reputation)}</reputation>
					<upvotes>{data($user/@UpVotes)}</upvotes>
					<downvotes>{data($user/@DownVotes)}</downvotes>
					<badges>{local:getBadges($user)}</badges>
					<top_post>{data($topPost/@Body)}</top_post>
				</user>
		}</users>
}</result>
